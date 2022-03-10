-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_DateDiff
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_DateDiff]') and xtype in (N'FN', N'IF', N'TF'))
begin
	print '**** Drop Function dbo.fn_DateDiff.'
	drop function [dbo].[fn_DateDiff]
	print '**** Creating Function dbo.fn_DateDiff...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_DateDiff
	(	
		@pdtDateFrom	datetime,
		@pdtDateTo	datetime
	)
Returns varchar(24)

-- FUNCTION :	fn_DateDiff
-- VERSION :	1
-- DESCRIPTION:	Returns an accurate difference between two dates
--		where the difference is described as: sYYYY-MM-DD hh:mm:ss.lll
--		where:	s	Sign (+ or -)
--			YYYY	Years
--			MM	Months
--			DD	Days
--			hh	Hours
--			mm	Minutes
--			ss	Seconds
--			lll	Miliseconds
		

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 01 Apr 06	MF	11943	1	Function created

as
Begin
RETURN
(
Select	CASE(sgn) WHEN 1 THEN '+' ELSE '-' END +
	RIGHT('000'	+ CAST(y	as varchar(4)), 4) + '-' +
	RIGHT('0'	+ CAST(m	as varchar(2)), 2) + '-' +
	RIGHT('0'	+ CAST(d	as varchar(2)), 2) + ' ' +
	RIGHT('0'	+ CAST(h	as varchar(2)), 2) + ':' +
	RIGHT('0'	+ CAST(mi	as varchar(2)), 2) + ':' +
	RIGHT('0'	+ CAST(s	as varchar(2)), 2) + '.' +
	RIGHT('00'	+ CAST(ms	as varchar(3)), 3)
From   (Select	from_ts,
		to_ts,
		sgn,
		y,
		m,
		d,
		s / 3600	as h,
		s % 3600 / 60	as mi,
		s % 60		as s,
		(1000 + DATEPART(ms, to_ts) - DATEPART(ms, from_ts)) %  1000 as ms
	From   (Select	from_ts,
			to_ts,
			sgn,
			y,
			m - DATEDIFF(month, from_ts, y_ts) as m,
			d - DATEDIFF(day, from_ts, m_ts) as d,
			DATEDIFF(second, d_ts, to_ts) as s
		From   (Select	*,
				DATEADD(year,  y, from_ts) as y_ts,
				DATEADD(month, m, from_ts) as m_ts,
				DATEADD(day,   d, from_ts) as d_ts
			From   (Select	from_ts,
					to_ts,
					sgn,
					y - CASE WHEN(DATEADD(year,  y, from_ts)> to_ts) THEN 1 ELSE 0 END as y,
					m - CASE WHEN(DATEADD(month, m, from_ts)> to_ts) THEN 1 ELSE 0 END as m,
					d - CASE WHEN(DATEADD(day,   d, from_ts)> to_ts) THEN 1 ELSE 0 END as d
				From   (Select	*,
						DATEDIFF(year,  from_ts, to_ts) as y,
						DATEDIFF(month, from_ts, to_ts) as m,
						DATEDIFF(day,   from_ts, to_ts) as d
					From   (Select	CASE WHEN(from_ts <= to_ts) THEN from_ts ELSE to_ts   END as from_ts,
							CASE WHEN(from_ts <= to_ts) THEN to_ts   ELSE from_ts END as to_ts,
							CASE WHEN(from_ts <= to_ts) THEN 1       ELSE -1      END as sgn
						From   (Select	@pdtDateFrom as from_ts,
								@pdtDateTo   as to_ts
							) as D0
						) as D1
					) as D2
				) as D3
			) as D4
		) as D5
	) as D6
)
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.fn_DateDiff to public
GO
