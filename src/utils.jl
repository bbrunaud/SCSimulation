function getlowerboundnz(var)
    for k in keys(var)
        lb = getlowerbound(var[k...])
        if lb > 0
            println(k, lb)
        end
    end
end

function getupperboundnz(var)
    for k in keys(var)
        lb = getupperbound(var[k...])
        if lb > 0
            println(k, lb)
        end
    end
end

function getvaluenz(var)
    for k in keys(var)
        lb = JuMP.getvalue(var[k...])
        if lb > 0
            println(k, lb)
        end
    end
end
