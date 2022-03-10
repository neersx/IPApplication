using System;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Web.BatchEventUpdate.Models;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.
    MenuFacts
{
    public class MenuFixture : BatchEventUpdateControllerFixture
    {
        public MenuFixture(InMemoryDbContext db) : base(db)
        {
        }

        public OpenActionModel[] Result { get; private set; }

        public async Task Run()
        {
            try
            {
                Result = await Subject.Menu(TempStorageId);
            }
            catch (Exception exception)
            {
                Exception = exception;
            }
        }
    }
}