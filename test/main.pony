use "ponytest"
use "../crdt"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  
  fun tag tests(test: PonyTest) =>
    test(TestGSet)
    test(TestP2Set)
    test(TestLWWSet)
