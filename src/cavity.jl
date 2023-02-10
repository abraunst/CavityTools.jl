function cavity!(dest, source, op, init)
    @assert length(dest) == length(source)
    isempty(source) && return init
    if length(source) == 1
        @inbounds dest[begin] = init 
        return op(first(source), init)
    end
    Iterators.accumulate!(op, dest, source)
    full = op(dest[end], init)
    right = init
    for (i,s)=zip(lastindex(dest):-1:firstindex(dest)+1,Iterators.reverse(source))
        @inbounds dest[i] = op(dest[i-1], right);
        right = op(s, right);
    end
    @inbounds dest[begin] = right
    full
end

function cavity(source, op, init)
    dest = [init for _ in source]
    full = cavity!(dest, source, op, init)
    dest, full
end
