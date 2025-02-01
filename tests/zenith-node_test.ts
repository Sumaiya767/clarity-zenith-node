import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensures node registration works with sufficient stake",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet1 = accounts.get("wallet_1")!;

    let block = chain.mineBlock([
      Tx.contractCall("zenith-node", "register-node", 
        [types.uint(100000)], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    
    let nodeInfo = chain.callReadOnlyFn("zenith-node", "get-node-info",
      [types.principal(wallet1.address)], deployer.address);
      
    nodeInfo.result.expectSome();
  },
});

Clarinet.test({
  name: "Prevents registration with insufficient stake",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get("wallet_1")!;

    let block = chain.mineBlock([
      Tx.contractCall("zenith-node", "register-node",
        [types.uint(50000)], wallet1.address)
    ]);
    
    block.receipts[0].result.expectErr().expectUint(101);
  },
});

Clarinet.test({
  name: "Only owner can update node status",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("zenith-node", "update-status",
        [types.principal(wallet1.address), 
         types.ascii("inactive")], wallet1.address)
    ]);
    
    block.receipts[0].result.expectErr().expectUint(100);
  },
});
