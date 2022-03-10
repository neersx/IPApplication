﻿using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.MenuFacts
{
    public class WhenBothRolesAndUserControlAreSpecifiedAndUserHasAccessInUserControl : FactBase
    {
        [Fact]
        public async Task It_should_return_data_entry_task_if_the_user_has_access_in_user_control()
        {
            var fixture = new MenuFixture(Db);

            RolesControlBuilder.For(fixture.SelectedDataEntryTask, Fixture.Integer()).Build().In(Db);
            UserControlBuilder.For(fixture.SelectedDataEntryTask, Fixture.String()).Build().In(Db);
            UserControlBuilder.For(fixture.SelectedDataEntryTask, fixture.SecurityContext.User.UserName).Build().In(Db);

            await fixture.Run();

            Assert.Contains(fixture.Result.First(oam => oam.Action.ActionId == fixture.ExistingOpenAction.ActionId)
                                   .DataEntryTasks, det => det.Id == fixture.SelectedDataEntryTask.Id);
        }
    }
}