using System.Linq;
using System.Threading.Tasks;
using System.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.BatchEventUpdate.Models;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.
    SaveFacts
{
    public class SaveFixture : BatchEventUpdateControllerFixture
    {
        public SaveFixture(InMemoryDbContext db) : base(db)
        {
            ExistingCriteria = ExistingOpenAction.Criteria;
            ExistingDataEntryTask = ExistingOpenAction.Criteria.DataEntryTasks.First();
        }

        public SaveBatchEventsModel SaveBatchEventsModel { get; set; }
        public SingleCaseUpdatedResultModel[] Result { get; private set; }
        public new HttpException Exception { get; private set; }
        public CaseDataEntryTaskModel[] CaseDataEntryTaskModels { get; set; }
        public DataEntryTask ExistingDataEntryTask { get; }
        public Criteria ExistingCriteria { get; }

        public async Task Run()
        {
            try
            {
                Result = await Subject.Save(SaveBatchEventsModel);
            }
            catch (HttpException ex)
            {
                Exception = ex;
            }
        }
    }
}