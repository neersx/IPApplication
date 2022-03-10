using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Tests.Fakes;
using Inprotech.Web.BatchEventUpdate.Models;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.
    EventsFacts
{
    public class EventsFixture : BatchEventUpdateControllerFixture
    {
        public EventsFixture(InMemoryDbContext db) : base(db)
        {
        }

        protected bool? UseNextCycle { get; set; }

        public BatchEventsModel Result { get; set; }

        public new HttpResponseException Exception { get; set; }

        public async Task Run()
        {
            try
            {
                Result = await Subject.Events(
                                              new EventsRequestModel
                                              {
                                                  TempStorageId = TempStorageId,
                                                  CriteriaId = SelectedDataEntryTask.Criteria.Id,
                                                  DataEntryTaskId = SelectedDataEntryTask.Id
                                              });
            }
            catch (HttpResponseException ex)
            {
                Exception = ex;
            }
        }
    }
}