function a = constrain(num, max_val)
    if num < 1
        a = 1;
    elseif num > max_val
        a = max_val;
    else
        a = num;
    end
end