using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration.Accounting.Time.Posting;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Accounting.Time;
using Newtonsoft.Json.Linq;
using Xunit;

namespace Inprotech.Tests.Integration.Accounting.Time.Posting
{
    public class PostTimeJobFacts
    {
        public class GetJobMethod : FactBase
        {
            [Fact]
            public void ReturnsPostTimeActivity()
            {
                var original = new PostTimeArgs();

                var r = new PostTimeJob()
                    .GetJob(JObject.FromObject(original));

                Assert.Equal("PostTimeJob.Execute", r.TypeAndMethod());

                var arg = (PostTimeArgs) r.Arguments[0];

                Assert.Equal(arg.GetType(), arg.GetType());
            }
        }

        public class ExecuteMethod : FactBase
        {
            [Fact]
            public async Task RunsPostInBackGround()
            {
                var args = new PostTimeArgs();
                var r = await new PostTimeJob().Execute(args);

                Assert.NotNull(r);
                var activityItems = ((ActivityGroup) r).Items.ToList();
                Assert.Equal("PostInBackground", ((SingleActivity) activityItems.Single()).Name);

                var arg = (PostTimeArgs) ((SingleActivity) activityItems[0]).Arguments[0];
                Assert.Equal(arg.GetType(), arg.GetType());
            }

            [Fact]
            public async Task PostMultipleStaffInBackground()
            {
                var args = new PostTimeArgs
                {
                    SelectedStaffDates = new List<PostableDate>
                    {
                        new(Fixture.PastDate(), 10, 10, Fixture.UniqueName(), Fixture.Integer())
                    }
                };
                var r = await new PostTimeJob().Execute(args);

                Assert.NotNull(r);
                var activityItems = ((ActivityGroup) r).Items.ToList();
                Assert.Equal("PostMultipleStaffInBackground", ((SingleActivity) activityItems.Single()).Name);

                var arg = (PostTimeArgs) ((SingleActivity) activityItems[0]).Arguments[0];
                Assert.Equal(arg.GetType(), arg.GetType());
            }
        }
    }
}