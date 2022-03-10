using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Web.KeepOnTopNotes;
using InprotechKaizen.Model;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.KeepOnTopNotes
{
    public class KeepOnTopNotesControllerFacts
    {
        public class GetKotNotesForCase : FactBase
        {
            [Fact]
            public async Task ReturnsAllKotNotesForCase()
            {
                var f = new KeepOnTopNotesControllerFixture();
                var data = new List<KotNotesItem>
                {
                    new KotNotesItem
                    {
                        CaseRef = Fixture.String(),
                        BackgroundColor = Fixture.String(),
                        Note = Fixture.String()
                    },
                    new KotNotesItem
                    {
                        CaseRef = Fixture.String(),
                        BackgroundColor = Fixture.String(),
                        Note = Fixture.String()
                    }
                };
                f.KeepOnTopNotesView.GetKotNotesForCase(1, KnownKotModules.Case).Returns(data);
                var r = await f.Subject.GetKotNotesForCase(1, KnownKotModules.Case);
                var results = (IEnumerable<KotNotesItem>) r.ToArray();

                Assert.Equal(2, results.ToArray().Length);
            }
        }

        public class GetKotNotesForName : FactBase
        {
            [Fact]
            public async Task ReturnsAllKotNotesForName()
            {
                var f = new KeepOnTopNotesControllerFixture();
                var data = new List<KotNotesItem>
                {
                    new KotNotesItem
                    {
                        Note = Fixture.String(),
                        BackgroundColor = Fixture.String(),
                        Name = Fixture.String(),
                        NameTypes = Fixture.String()
                    },
                    new KotNotesItem
                    {
                        Note = Fixture.String(),
                        BackgroundColor = Fixture.String(),
                        Name = Fixture.String(),
                        NameTypes = Fixture.String()
                    }
                };
                f.KeepOnTopNotesView.GetKotNotesForName(1, KnownKotModules.Name).Returns(data);
                var r = await f.Subject.GetKotNotesForName(1, KnownKotModules.Name);
                var results = (IEnumerable<KotNotesItem>) r.ToArray();

                Assert.Equal(2, results.ToArray().Length);
            }
        }
    }

    public class KeepOnTopNotesControllerFixture : IFixture<KeepOnTopNotesController>
    {
        public KeepOnTopNotesControllerFixture()
        {
            KeepOnTopNotesView = Substitute.For<IKeepOnTopNotesView>();

            Subject = new KeepOnTopNotesController(KeepOnTopNotesView);
        }

        public IKeepOnTopNotesView KeepOnTopNotesView { get; set; }
        public KeepOnTopNotesController Subject { get; set; }
    }
}