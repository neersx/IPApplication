using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Reminders;

#pragma warning disable 618

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class EmployeeReminderConsolidator : INameConsolidator
    {
        readonly IBatchedCommand _batchedCommand;
        readonly IDbContext _dbContext;

        public EmployeeReminderConsolidator(IDbContext dbContext, IBatchedCommand batchedCommand)
        {
            _dbContext = dbContext;
            _batchedCommand = batchedCommand;
        }

        public string Name => nameof(EmployeeReminderConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            var parameters = new Dictionary<string, object>
            {
                {"@to", to.Id},
                {"@from", from.Id}
            };

            await InsertEmployeeReminders(parameters);

            await UpdateNameNo(to, from);

            await UpdateAlertNameNo(to, from);

            await DeleteEmployeeReminders(from);
        }

        async Task DeleteEmployeeReminders(Name from)
        {
            await _dbContext.DeleteAsync(from e in _dbContext.Set<StaffReminder>()
                                         where e.StaffId == @from.Id
                                         select e);
        }

        async Task UpdateAlertNameNo(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from e in _dbContext.Set<StaffReminder>()
                                         where e.AlertNameId == @from.Id
                                         select e,
                                         _ => new StaffReminder {AlertNameId = to.Id});
        }

        async Task UpdateNameNo(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from e in _dbContext.Set<StaffReminder>()
                                         where e.NameId == @from.Id
                                         select e,
                                         _ => new StaffReminder {NameId = to.Id});
        }

        async Task InsertEmployeeReminders(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO EMPLOYEEREMINDER(	 
                EMPLOYEENO, MESSAGESEQ, CASEID, REFERENCE, EVENTNO, CYCLENO, DUEDATE, REMINDERDATE, READFLAG, SOURCE, HOLDUNTILDATE, DATEUPDATED, 
                SHORTMESSAGE, LONGMESSAGE, COMMENTS, SEQUENCENO, COMMENTS_TID, MESSAGE_TID, REFERENCE_TID, NAMENO, ALERTNAMENO)
		    SELECT   
                @to, E1.MESSAGESEQ, E1.CASEID, E1.REFERENCE, E1.EVENTNO, E1.CYCLENO, E1.DUEDATE, E1.REMINDERDATE, E1.READFLAG, E1.SOURCE, E1.HOLDUNTILDATE, E1.DATEUPDATED, 
                E1.SHORTMESSAGE, E1.LONGMESSAGE, E1.COMMENTS, E1.SEQUENCENO, E1.COMMENTS_TID, E1.MESSAGE_TID, E1.REFERENCE_TID, E1.NAMENO, E1.ALERTNAMENO
		    FROM EMPLOYEEREMINDER E1
		    left join EMPLOYEEREMINDER E2	on ( E2.EMPLOYEENO=@to
	 					and (E2.CASEID    =E1.CASEID    or (E2.CASEID    is null and E1.CASEID    is null))
	 					and (E2.EVENTNO   =E1.EVENTNO   or (E2.EVENTNO   is null and E1.EVENTNO   is null))
	 					and (E2.CYCLENO   =E1.CYCLENO   or (E2.CYCLENO   is null and E1.CYCLENO   is null))
	 					and (E2.REFERENCE =E1.REFERENCE or (E2.REFERENCE is null and E1.REFERENCE is null))
	 					and  E2.SEQUENCENO=E1.SEQUENCENO)
		    where E1.EMPLOYEENO=@from
		    and E2.EMPLOYEENO is null", parameters);
        }
    }
}