import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { PGlite } from '@electric-sql/pglite';

const root = new URL('../', import.meta.url);
const read = path => readFileSync(new URL(path, root), 'utf8');
const manifest = JSON.parse(read('database/manifest.json'));
const db = new PGlite();
let passed = 0;
let stage = '';
async function check(name, work) {
  stage = name;
  await work();
  passed++;
  console.log('PASS '+name);
}
async function one(sql, params=[]) { return (await db.query(sql,params)).rows[0]; }
async function scalar(sql, params=[]) { return Object.values(await one(sql,params))[0]; }
async function command(key, type, args) {
  if(type === 'record_transaction' && !('description' in args)) args = {...args, description:'Synthetic '+key};
  return scalar('select public.finance_command($1,$2,$3::jsonb)',[key,type,JSON.stringify(args)]);
}
async function status() { return scalar('select public.get_status_until_next_income(now(),null)'); }
async function mustReject(work, pattern) { await assert.rejects(work, pattern); }

try {
  const version=await scalar('select version()');
  console.log('Engine: '+version);
  await db.exec('CREATE ROLE anon; CREATE ROLE authenticated; CREATE ROLE service_role BYPASSRLS;');
  await check('fresh bootstrap and empty status',async()=>{
    await db.exec(read('database/bootstrap.sql'));
    const s=await status();
    assert.equal(s.integrity_ok,true);
    assert.equal(s.cash.actual_cash,0);
    assert.equal(s.liquidity.free_cash_until_next_income,null);
  });
  await check('catalog object counts',async()=>{
    const counts=await one("select (select count(*)::int from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='r') tables, (select count(*)::int from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='v') views, (select count(*)::int from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public') functions, (select count(*)::int from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='S') sequences, (select count(*)::int from pg_constraint c join pg_namespace n on n.oid=c.connamespace where n.nspname='public' and c.contype<>'n') constraints, (select count(*)::int from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and not t.tgisinternal) triggers, (select count(*)::int from pg_index i join pg_class c on c.oid=i.indrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and not exists(select 1 from pg_constraint co where co.conindid=i.indexrelid)) additional_indexes");
    assert.deepEqual(counts,manifest.expected_counts);
  });
  await check('all 76 function bodies compile after dependencies exist',async()=>{
    for(const f of manifest.functions) await db.exec(read(f.path));
  });
  await check('owner-only installation and invoker views',async()=>{
    const rows=(await db.query("select c.relname,c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='r'")).rows;
    assert.ok(rows.every(r=>r.relrowsecurity));
    for(const role of ['anon','authenticated','service_role']) {
      assert.equal(await scalar("select has_table_privilege($1,'public.transactions','SELECT')",[role]),false);
      assert.equal(await scalar("select has_function_privilege($1,'public.get_status_until_next_income(timestamptz,numeric)','EXECUTE')",[role]),false);
    }
    const views=(await db.query("select reloptions from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='v'")).rows;
    assert.ok(views.every(r=>r.reloptions.includes('security_invoker=true')));
    await db.exec('SET ROLE anon');
    try { await mustReject(()=>db.query('select * from public.transactions'),/permission denied/); }
    finally { await db.exec('RESET ROLE'); }
  });
  await check('bootstrap rejects nonempty schema without destroying it',async()=>{
    await mustReject(()=>db.exec(read('database/bootstrap.sql')),/requires an empty public schema/);
    await db.exec('ROLLBACK');
    assert.equal(await scalar('select count(*)::int from public.transactions'),0);
  });
  await check('synthetic demo loads and deferred constraints commit',async()=>{
    await db.exec(read('database/demo/seed.sql'));
    const s=await status();
    assert.equal(s.integrity_ok,true);
    assert.equal(s.cash.actual_cash,38750);
    assert.equal(s.weekly_budget.spend,450);
    assert.equal(s.weekly_budget.budget,10000);
  });
  const ids=Object.fromEntries((await db.query('select id,name from public.accounts')).rows.map(r=>[r.name,r.id]));
  const food=await scalar("select id from public.categories where name='Demo Food'");
  const event=await scalar("select id from public.cash_flow_events where description='Demo Loan Payment'");
  const loan=await scalar("select id from public.liabilities where name='Demo Loan'");
  await check('demo refuses to append to populated tables',async()=>{
    await mustReject(()=>db.exec(read('database/demo/seed.sql')),/demo requires empty tables/);
    await db.exec('ROLLBACK');
    assert.equal(await scalar('select count(*)::int from public.transactions'),2);
  });
  await check('request retry preserves one transaction and rejects changed payload',async()=>{
    const row=await one("select id,request_payload from public.transactions where external_ref='demo-lunch'");
    const again=await command('demo-lunch',row.request_payload.command,row.request_payload.args);
    assert.equal(again,row.id);
    await mustReject(()=>command('demo-lunch','record_transaction',{...row.request_payload.args,amount:999}),/different arguments/);
    assert.equal(await scalar("select count(*)::int from public.transactions where external_ref='demo-lunch'"),1);
  });
  await check('funding is not execution; paying buffer does not subtract free cash twice',async()=>{
    const before=Number(await scalar('select public.get_free_cash(now())'));
    const state=await one('select * from public.get_cash_flow_event_state_as_of(now()) where event_id=$1',[event]);
    assert.equal(state.derived_status,'secured');assert.equal(Number(state.paid_amount),0);
    const at=await scalar('select now()::text');
    await command('test-execute','execute_event',{event_id:event,amount:800,occurred_at:at,principal_amount:700,interest_amount:100,fee_amount:0});
    const after=Number(await scalar('select public.get_free_cash(now())'));
    assert.equal(after,before);
    assert.equal(Number(await scalar('select public.get_account_balance($1,now())',[ids['Demo Buffer']])),0);
    const b=await one('select * from public.get_liability_balance($1,now())',[loan]);
    assert.equal(Number(b.principal_balance),4300);
    assert.equal(await scalar('select derived_status from public.get_cash_flow_event_state_as_of(now()) where event_id=$1',[event]),'executed');
    await mustReject(()=>command('test-too-much','execute_event',{event_id:event,amount:1}),/exceeds remaining|no remaining/);
  });
  await check('cash transfer and excluded expense have distinct budget effects',async()=>{
    const before=await status();const at=await scalar('select now()::text');
    await command('test-transfer','record_transaction',{transaction_type:'transfer',amount:500,from_account_id:ids['Demo Bank'],to_account_id:ids['Demo Cash'],occurred_at:at});
    let after=await status();assert.equal(after.cash.actual_cash,before.cash.actual_cash);assert.equal(after.weekly_budget.spend,before.weekly_budget.spend);
    await command('test-excluded','record_transaction',{transaction_type:'expense',amount:300,from_account_id:ids['Demo Bank'],budget_effect:'excluded',occurred_at:at});
    after=await status();assert.equal(after.cash.actual_cash,before.cash.actual_cash-300);assert.equal(after.weekly_budget.spend,before.weekly_budget.spend);
  });
  await check('card purchase uses budget once, repayment closes the cash reserve',async()=>{
    const before=await status();const at=await scalar('select now()::text');
    await command('test-card-buy','record_transaction',{transaction_type:'expense',amount:600,from_account_id:ids['Demo Card'],category_id:food,budget_effect:'life',occurred_at:at});
    let after=await status();assert.equal(after.cash.actual_cash,before.cash.actual_cash);assert.equal(after.weekly_budget.spend,before.weekly_budget.spend+600);
    assert.equal(Number(await scalar('select unsettled_budget_spend from public.get_credit_budget_position(now()) where account_id=$1',[ids['Demo Card']])),600);
    await command('test-card-repay','record_transaction',{transaction_type:'transfer',amount:600,from_account_id:ids['Demo Bank'],to_account_id:ids['Demo Card'],occurred_at:at});
    after=await status();assert.equal(after.cash.actual_cash,before.cash.actual_cash-600);assert.equal(after.weekly_budget.spend,before.weekly_budget.spend+600);
    assert.equal(Number(await scalar('select unsettled_budget_spend from public.get_credit_budget_position(now()) where account_id=$1',[ids['Demo Card']])),0);
  });
  await check('atomic correction maintains category allocations and rejects incomplete edits',async()=>{
    const tx=await scalar("select id from public.transactions where external_ref='demo-lunch'");
    await db.query("select public.correct_finance_transaction($1,'{}'::jsonb,$2::jsonb)",[tx,JSON.stringify([{category_id:food,amount:450}])]);
    await mustReject(()=>db.query("select public.correct_finance_transaction($1,'{\"amount\":451}'::jsonb)",[tx]),/category_allocation_mismatch|согласован|allocation/);
    assert.equal(Number(await scalar('select amount from public.transactions where id=$1',[tx])),450);
    await db.query("select public.correct_finance_transaction($1,$2::jsonb,$3::jsonb)",[tx,JSON.stringify({amount:460,from_account_id:ids['Demo Cash']}),JSON.stringify([{category_id:food,amount:460}])]);
    assert.equal(Number(await scalar('select amount from public.transaction_category_allocations where transaction_id=$1',[tx])),460);
    assert.equal(await scalar('select from_account_id from public.transactions where id=$1',[tx]),ids['Demo Cash']);
  });
  await check('snapshot cutoff excludes operations at the exact anchor',async()=>{
    const id=await scalar("insert into public.accounts(name,account_type) values('Test Anchor','other_asset') returning id");
    await db.query("insert into public.account_balance_snapshots(account_id,balance_date,balance_as_of,balance) values($1,'2026-01-05','2026-01-05T10:00:00+03',15000)",[id]);
    await command('test-anchor-equal','record_transaction',{transaction_type:'expense',amount:20,from_account_id:id,budget_effect:'excluded',occurred_at:'2026-01-05T10:00:00+03'});
    await command('test-anchor-after','record_transaction',{transaction_type:'expense',amount:300,from_account_id:id,budget_effect:'excluded',occurred_at:'2026-01-05T10:10:00+03'});
    assert.equal(Number(await scalar("select public.get_account_balance($1,'2026-01-05T10:05:00+03'::timestamptz)",[id])),15000);
    assert.equal(Number(await scalar("select public.get_account_balance($1,'2026-01-05T10:15:00+03'::timestamptz)",[id])),14700);
  });
  await check('forecast and integrity read contracts execute',async()=>{
    const forecast=await one('select * from public.get_financial_position_at(public.finance_business_date(now())+15,now(),null)');
    assert.ok(Number.isFinite(Number(forecast.free_cash)));
    const s=await status();assert.equal(s.integrity_ok,true);
  });
  console.log('PASS '+passed+' database checks');
} catch(e) {
  console.error(JSON.stringify({stage,message:e.message,code:e.code,detail:e.detail,where:e.where,stack:e.code?undefined:e.stack}));
  process.exitCode=1;
} finally { await db.close(); }
