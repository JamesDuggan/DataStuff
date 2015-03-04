-- the last 6 byte block has sorting precedence. Byte 10 is most significant
select cast(g as uniqueidentifier) from 
(
       values ('00000000-0000-0000-0000-0000000000AA')
            , ('00000000-0000-0000-0000-00000000AA00')
            , ('00000000-0000-0000-0000-000000AA0000')
            , ('00000000-0000-0000-0000-0000AA000000')
            , ('00000000-0000-0000-0000-00AA00000000')
            , ('00000000-0000-0000-0000-AA0000000000')
) t(g) 
order  by
       1;
go


-- following the last 6 byte block,
-- the next sorting precedence is the last 2 byte block. Byte 8 is most significant.
select cast(g as uniqueidentifier) from 
(
       values ('00000000-0000-0000-00AA-000000000000')
            , ('00000000-0000-0000-AA00-000000000000')
) t(g) 
order  by
       1;
go

-- following the last 8 bytes, 
-- the next sorting precedence is the middle 2 byte block. Byte 7 is most significant then byte 6.
-- then the first 2 byte block. Byte 5 is most significant.
-- finally the first 4 byte block. Byte 3 is most significant.
select cast(g as uniqueidentifier) from 
(
       values ('AA000000-0000-0000-0000-000000000000')
            , ('00AA0000-0000-0000-0000-000000000000')
            , ('0000AA00-0000-0000-0000-000000000000')
            , ('000000AA-0000-0000-0000-000000000000')
            , ('00000000-AA00-0000-0000-000000000000')
            , ('00000000-00AA-0000-0000-000000000000')
            , ('00000000-0000-AA00-0000-000000000000')
            , ('00000000-0000-00AA-0000-000000000000')
) t(g) 
order  by
       1;
go