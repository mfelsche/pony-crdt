use "collections"

class ref GCounter[A: (Integer[A] val & Unsigned) = U64]
  is (Comparable[GCounter[A]] & Convergent[GCounter[A]])
  """
  A mutable grow-only counter. That is, the value can only be increased.

  This data type tracks the state seen from each replica, thus the size of the
  state will grow proportionally with the number of total replicas. New replicas
  may be added as peers at any time, provided that they use unique ids.
  Read-only replicas which never change state and only observe need not use
  unique ids, and should use an id of zero, by convention.

  The state of each replica represents the value incremented so far by that
  particular replica. This local value may only ever increase, never decrease.
  The total value of the counter is the sum of the local value of all replicas.

  When converging state from other replicas, we retain the maximum observed
  value from each replica id. Because a higher value always implies later
  logical time for that replica, and we only keep the highest value seen from
  each replica, we will always retain the latest value seen from each replica.

  Because the view of values from each other replica is eventually consistent,
  the summed value of the overall counter is also eventually consistent.

  All mutator methods accept and return a convergent delta-state.
  """
  let _id: ID
  embed _data: Map[ID, A]

  new ref create(id': ID) =>
    """
    Instantiate the GCounter under the given unique replica id.
    """
    _id   = id'
    _data = Map[ID, A]

  fun apply(): A =>
    """
    Return the current value of the counter (the sum of all replica values).
    """
    value()

  fun value(): A =>
    """
    Return the current value of the counter (the sum of all replica values).
    """
    var sum = A(0)
    for v in _data.values() do sum = sum + v end
    sum

  fun ref _data_update(id': ID, value': A) => _data(id') = value'

  fun ref increment[D: GCounter[A] ref = GCounter[A]](
    value': A = 1,
    delta': D = recover GCounter[A](0) end)
  : D^ =>
    """
    Increment the counter by the given value.
    Accepts and returns a convergent delta-state.
    """
    try
      let v' = _data.upsert(_id, value', {(v: A, value': A): A => v + value' })?
      delta'._data_update(_id, v')
    end
    consume delta'

  fun ref converge(that: GCounter[A] box): Bool =>
    """
    Converge from the given GCounter into this one.
    For each replica state, we select the maximum value seen so far (grow-only).
    Returns true if the convergence added new information to the data structure.
    """
    var changed = false
    for (id, value') in that._data.pairs() do
      // TODO: introduce a stateful upsert in ponyc Map?
      if try value' > _data(id)? else true end then
        _data(id) = value'
        changed = true
      end
    end
    changed

  fun string(): String iso^ =>
    """
    Return a best effort at printing the register. If A is Stringable, use
    the string representation of the value; otherwise print as a question mark.
    """
    iftype A <: Stringable val then
      value().string()
    else
      "?".clone()
    end

  fun eq(that: GCounter[A] box): Bool => value().eq(that.value())
  fun ne(that: GCounter[A] box): Bool => value().ne(that.value())
  fun lt(that: GCounter[A] box): Bool => value().lt(that.value())
  fun le(that: GCounter[A] box): Bool => value().le(that.value())
  fun gt(that: GCounter[A] box): Bool => value().gt(that.value())
  fun ge(that: GCounter[A] box): Bool => value().ge(that.value())
