using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.InproDoc;
using Inprotech.Web.InproDoc.Config;
using Inprotech.Web.Picklists;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class EntryPointPicklistControllerFacts
    {
        public class EntryPointsMethod : FactBase
        {
            readonly CommonQueryParameters _queryParameters = new CommonQueryParameters();

            [Fact]
            public void ReturnsEntryPointsContainingMatchingDescription()
            {
                var f = new EntryPointPicklistControllerFixture();
                var entryPoints = f.Setup();

                var r = f.Subject.EntryPoints(_queryParameters, "name");
                var ep = r.Data.OfType<dynamic>().ToArray();

                Assert.Equal(2, ep.Length);
                Assert.Equal(entryPoints.Single(_ => _.Name == "2").Description, ep.First().Description);
                Assert.Equal(entryPoints.Single(_ => _.Name == "4").Description, ep.Last().Description);
            }

            [Fact]
            public void ReturnsEntryPointsContainingMatchingName()
            {
                var f = new EntryPointPicklistControllerFixture();
                var entryPoints = f.Setup();

                var r = f.Subject.EntryPoints(_queryParameters, "1");
                var ep = r.Data.OfType<dynamic>().ToArray();

                Assert.Single(ep);
                Assert.Equal(entryPoints.Single(_ => _.Name == "1").Name, ep.First().Name);
            }

            [Fact]
            public void ReturnsEntryPointsSortedByName()
            {
                var f = new EntryPointPicklistControllerFixture();
                var entryPoints = f.Setup();

                var r = f.Subject.EntryPoints(_queryParameters);
                var ep = r.Data.OfType<dynamic>().ToArray();

                Assert.Equal(4, ep.Length);
                Assert.Equal(entryPoints.OrderBy(_ => _.Name).First().Name, ep.First().Name);
                Assert.Equal(entryPoints.OrderByDescending(_ => _.Name).First().Name, ep.Last().Name);
            }
        }
    }

    public class EntryPointPicklistControllerFixture : IFixture<EntryPointPicklistController>
    {
        public EntryPointPicklistControllerFixture()
        {
            PassThruManager = Substitute.For<IPassThruManager>();
            Subject = new EntryPointPicklistController(PassThruManager);
            PassThruManager.GetEntryPoints().Returns(Setup());
        }

        public IPassThruManager PassThruManager { get; set; }
        public EntryPointPicklistController Subject { get; }

        public List<EntryPoint> Setup()
        {
            var entryPoint1 = new EntryPoint {Name = "1", Description = "The Refererence (IRN) of a Case"};

            var entryPoint2 = new EntryPoint {Name = "2", Description = "The Code of a Name"};

            var entryPoint3 = new EntryPoint {Name = "3", Description = "The Question No"};

            var entryPoint4 = new EntryPoint {Name = "4", Description = "The NameNo of a Name"};

            var entryPoints = new List<EntryPoint> {entryPoint1, entryPoint2, entryPoint3, entryPoint4};

            return entryPoints;
        }
    }
}