# Convert # of Rata Die days to proleptic Gregorian calendar y,m,d,w
# Reference: http://mysite.verizon.net/aesir_research/date/date0.htm
function _day2date(days)
    z = days + 306; h = 100z - 25; a = fld(h,3652425); b = a - fld(a,4);
    y = fld(100b+h,36525); c = b + z - 365y - fld(y,4); m = div(5c+456,153);
    d = c - div(153m-457,5); return m > 12 ? (y+1,m-12,d) : (y,m,d)
end
function _year(days)
   z = days + 306; h = 100z - 25; a = fld(h,3652425); b = a - fld(a,4);
   y = fld(100b+h,36525); c = b + z - 365y - fld(y,4); m = div(5c+456,153); 
   return m > 12 ? y+1 : y
end
function _yearmonth(days)
    z = days + 306; h = 100z - 25; a = fld(h,3652425); b = a - fld(a,4);
    y = fld(100b+h,36525); c = b + z - 365y - fld(y,4); m = div(5c+456,153); 
    return m > 12 ? (y+1,m-12) : (y,m)
end
function _month(days)
    z = days + 306; h = 100z - 25; a = fld(h,3652425); b = a - fld(a,4);
    y = fld(100b+h,36525); c = b + z - 365y - fld(y,4); m = div(5c+456,153);
    return m > 12 ? m-12 : m
end
function _monthday(days)
    z = days + 306; h = 100z - 25; a = fld(h,3652425); b = a - fld(a,4);
    y = fld(100b+h,36525); c = b + z - 365y - fld(y,4); m = div(5c+456,153);
    d = c - div(153m-457,5); return m > 12 ? (m-12,d) : (m,d)
end
function _day(days)
    z = days + 306; h = 100z - 25; a = fld(h,3652425); b = a - fld(a,4);
    y = fld(100b+h,36525); c = b + z - 365y - fld(y,4); m = div(5c+456,153); 
    return c - div(153m-457,5)
end
# https://en.wikipedia.org/wiki/Talk:ISO_week_date#Algorithms
function _week(days)
    w = div(abs(days-1),7) % 20871
    c,w = divrem((w + (w >= 10435)),5218)
    w = (w*28+[15,23,3,11][c+1]) % 1461
    return div(w,28) + 1
end

# Accessor functions
value(dt::TimeType) = dt.instant.periods.value
_days(dt::Date) = value(dt)
_days(dt::DateTime) = fld(value(dt),86400000)
year(dt::TimeType) = _year(_days(dt))
month(dt::TimeType) = _month(_days(dt))
week(dt::TimeType) = _week(_days(dt))
day(dt::TimeType) = _day(_days(dt))
hour(dt::DateTime)   = mod(fld(value(dt),3600000),24)
minute(dt::DateTime) = mod(fld(value(dt),60000),60)
second(dt::DateTime) = mod(fld(value(dt),1000),60)
millisecond(dt::DateTime) = mod(value(dt),1000)

dayofmonth(dt::TimeType) = day(dt)
yearmonth(dt::TimeType) = _yearmonth(_days(dt))
monthday(dt::TimeType) = _monthday(_days(dt))
yearmonthday(dt::TimeType) = _day2date(_days(dt))
#TODO: add hourminute, hourminutesecond

@vectorize_1arg TimeType year
@vectorize_1arg TimeType month
@vectorize_1arg TimeType day
@vectorize_1arg TimeType week
@vectorize_1arg DateTime hour
@vectorize_1arg DateTime minute
@vectorize_1arg DateTime second
@vectorize_1arg DateTime millisecond

@vectorize_1arg TimeType dayofmonth
@vectorize_1arg TimeType yearmonth
@vectorize_1arg TimeType monthday
@vectorize_1arg TimeType yearmonthday

# Conversion/Promotion
Date(dt::TimeType) = convert(Date,dt)
DateTime(dt::TimeType) = convert(DateTime,dt)
Base.convert(::Type{DateTime},dt::Date) = DateTime(UTM(value(dt)*86400000))
Base.convert(::Type{Date},dt::DateTime) = Date(UTD(_days(dt)))
Base.convert{R<:Real}(::Type{R},x::DateTime) = convert(R,value(x))
Base.convert{R<:Real}(::Type{R},x::Date)     = convert(R,value(x))

@vectorize_1arg DateTime Date
@vectorize_1arg Date DateTime

# Traits, Equality
Base.isfinite{T<:TimeType}(::Union(TimeType,T)) = true
calendar(dt::DateTime) = ISOCalendar
calendar(dt::Date) = ISOCalendar
Base.precision(dt::DateTime) = UTInstant{Millisecond}
Base.precision(dt::Date) = UTInstant{Day}
Base.typemax(::Union(DateTime,Type{DateTime})) = DateTime(146138512,12,31,23,59,59)
Base.typemin(::Union(DateTime,Type{DateTime})) = DateTime(-146138511,1,1,0,0,0)
Base.typemax(::Union(Date,Type{Date})) = Date(252522163911149,12,31)
Base.typemin(::Union(Date,Type{Date})) = Date(-252522163911150,1,1)
# Date-DateTime promotion, <, ==
Base.promote_rule(::Type{Date},x::Type{DateTime}) = x
Base.isless(x::Date,y::Date) = isless(value(x),value(y))
Base.isless(x::DateTime,y::DateTime) = isless(value(x),value(y))
Base.isless(x::TimeType,y::TimeType) = isless(promote(x,y)...)
==(x::TimeType,y::TimeType) = ===(promote(x,y)...)

# TODO: optimize this
function Base.string(dt::DateTime)
    y,m,d = _day2date(_days(dt))
    h,mi,s = hour(dt),minute(dt),second(dt)
    yy = y < 0 ? @sprintf("%05i",y) : lpad(y,4,"0")
    mm = lpad(m,2,"0")
    dd = lpad(d,2,"0")
    hh = lpad(h,2,"0")
    mii = lpad(mi,2,"0")
    ss = lpad(s,2,"0")
    ms = millisecond(dt) == 0 ? "" : string(millisecond(dt)/1000.0)[2:end]
    return "$yy-$mm-$(dd)T$hh:$mii:$ss$ms"
end
Base.show(io::IO,x::DateTime) = print(io,string(x))
function Base.string(dt::Date)
    y,m,d = _day2date(value(dt))
    yy = y < 0 ? @sprintf("%05i",y) : lpad(y,4,"0")
    mm = lpad(m,2,"0")
    dd = lpad(d,2,"0")
    return "$yy-$mm-$dd"
end
Base.show(io::IO,x::Date) = print(io,string(x))
