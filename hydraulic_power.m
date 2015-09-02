function result=hydraulic_power(x,u)
if (x<=0)
    result=1;
else
    result=u*x*hydraulic_power(x-1);
end

end