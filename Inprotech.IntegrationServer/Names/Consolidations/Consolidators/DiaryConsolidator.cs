using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class DiaryConsolidator : INameConsolidator
    {
        readonly IBatchedCommand _batchedCommand;
        readonly IDbContext _dbContext;

        public DiaryConsolidator(IDbContext dbContext, IBatchedCommand batchedCommand)
        {
            _dbContext = dbContext;
            _batchedCommand = batchedCommand;
        }

        public string Name => nameof(DiaryConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            var parameters = new Dictionary<string, object>
            {
                {"@to", to.Id},
                {"@from", from.Id}
            };

            await InsertDiary(parameters);

            await DeleteDiaryForEmployee(from);

            await UpdateDiaryForName(to, from);
        }

        async Task UpdateDiaryForName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from d in _dbContext.Set<Diary>()
                                         where d.NameNo == @from.Id
                                         select d,
                                         _ => new Diary{ NameNo = to.Id});
        }

        async Task DeleteDiaryForEmployee(Name from)
        {
            await _dbContext.DeleteAsync(from d in _dbContext.Set<Diary>()
                                         where d.EmployeeNo == @from.Id
                                         select d);
        }

        async Task InsertDiary(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO DIARY (	 
                EMPLOYEENO, ENTRYNO, ACTIVITY, CASEID, NAMENO, STARTTIME, FINISHTIME, TOTALTIME, TOTALUNITS, TIMECARRIEDFORWARD, UNITSPERHOUR, TIMEVALUE, 
                CHARGEOUTRATE, WIPENTITYNO, TRANSNO, WIPSEQNO, NOTES, NARRATIVENO, SHORTNARRATIVE, LONGNARRATIVE, DISCOUNTVALUE, FOREIGNCURRENCY, FOREIGNVALUE, 
                EXCHRATE, FOREIGNDISCOUNT, QUOTATIONNO, PARENTENTRYNO, COSTCALCULATION1, COSTCALCULATION2, PRODUCTCODE, ISTIMER, CREATEDON)
		    SELECT   
                @to, 
                D.ENTRYNO+CASE WHEN(D1.ENTRYNO is null) THEN 0 ELSE D1.ENTRYNO+1 END,
                ACTIVITY, CASEID, NAMENO, STARTTIME, FINISHTIME, TOTALTIME, TOTALUNITS, TIMECARRIEDFORWARD, UNITSPERHOUR, TIMEVALUE, 
                CHARGEOUTRATE, WIPENTITYNO, TRANSNO, WIPSEQNO, NOTES, NARRATIVENO, SHORTNARRATIVE, LONGNARRATIVE, DISCOUNTVALUE, FOREIGNCURRENCY, FOREIGNVALUE, 
                EXCHRATE, FOREIGNDISCOUNT, QUOTATIONNO, PARENTENTRYNO, COSTCALCULATION1, COSTCALCULATION2, PRODUCTCODE, ISTIMER, CREATEDON
		    FROM DIARY D
		    left join (	select EMPLOYEENO, max(ENTRYNO) as ENTRYNO
				    from DIARY
				    where EMPLOYEENO=@to
				    group by EMPLOYEENO) D1
					    on (D1.EMPLOYEENO=@to)
		    where D.EMPLOYEENO=@from", parameters);
        }
    }
}