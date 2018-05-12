use "_private"

interface Causal[A: Causal[A] ref] is Convergent[A]
  new ref create(id: ID)
  new ref _create_in(ctx: DotContext)
  fun _context(): this->DotContext
  fun ref _converge_empty_in(ctx': DotContext box): Bool
  fun is_empty(): Bool
  fun ref clear[D: A ref = A](delta': D = recover D(0) end): D