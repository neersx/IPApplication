using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Cases.Maintenance.Models;
using Inprotech.Web.Cases.Maintenance.Updaters;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Maintenance.Updaters
{
    public class FileLocationsTopicUpdaterFacts : FactBase
    {
        [Fact]
        public void ShouldCreateFileLocations()
        {
            var f = new FileLocationsTopicUpdaterFixture(Db);
            var @case = new Case().In(Db);
            var fileLocation = new TableCodeBuilder().For(TableTypes.FileLocation).Build().In(Db);
            var filePart1 = new CaseFilePart(@case.Id) { FilePart = Fixture.Short(), FilePartTitle = Fixture.String() }.In(Db);
            var saveModel = new FileLocationsSaveModel
            {
                Rows = new[]
                {
                    new FileLocationsData
                    {
                        FilePartId = filePart1.FilePart,
                        FileLocationId = fileLocation.Id,
                        WhenMoved = Fixture.Date(),
                        BayNo = Fixture.String()
                    }
                }
            };

            var saveModelJObject = JObject.FromObject(saveModel);
            f.Subject.UpdateData(saveModelJObject, null, @case);
            var model = saveModel.Rows[0];
            var fl = @case.CaseLocations.First();
            Assert.Equal(1, @case.CaseLocations.Count);
            Assert.Equal(model.WhenMoved, fl.WhenMoved);
            Assert.Equal(model.BayNo, fl.BayNo);
            Assert.Equal(model.FileLocationId, fl.FileLocationId);
            Assert.Equal(model.FilePartId, fl.FilePartId);
            Assert.Equal(@case.Id, fl.CaseId);
        }

        [Fact]
        public void AddSecondIfWhenMovedExists()
        {
            var f = new FileLocationsTopicUpdaterFixture(Db);
            var @case = new Case().In(Db);
            var date = Fixture.Date();
            var fileLocation = new TableCodeBuilder().For(TableTypes.FileLocation).Build().In(Db);
            var filePart1 = new CaseFilePart(@case.Id) { FilePart = Fixture.Short(), FilePartTitle = Fixture.String() }.In(Db);
            var existingLocation = new CaseLocation(@case, fileLocation, date).In(Db);
            @case.CaseLocations.Add(existingLocation);
            var saveModel = new FileLocationsSaveModel
            {
                Rows = new[]
                {
                    new FileLocationsData
                    {
                        FilePartId = filePart1.FilePart,
                        FileLocationId = fileLocation.Id,
                        WhenMoved = date,
                        BayNo = Fixture.String(),
                        RowKey = Fixture.Integer().ToString()
                    },
                    new FileLocationsData
                    {
                        FilePartId = filePart1.FilePart,
                        FileLocationId = fileLocation.Id,
                        WhenMoved = date,
                        BayNo = Fixture.String(),
                        RowKey = Fixture.Integer().ToString()
                    }
                }
            };

            var saveModelJObject = JObject.FromObject(saveModel);
            f.Subject.UpdateData(saveModelJObject, null, @case);
            var model = saveModel.Rows[0];
            var fl = @case.CaseLocations.ToArray()[1];
            Assert.Equal(3, @case.CaseLocations.Count);
            Assert.Equal(model.WhenMoved.AddSeconds(1).AddMilliseconds(DateTime.Now.Millisecond).Second, fl.WhenMoved.Second);
            Assert.Equal(model.BayNo, fl.BayNo);
            Assert.Equal(model.FileLocationId, fl.FileLocationId);
            Assert.Equal(model.FilePartId, fl.FilePartId);
            Assert.Equal(@case.Id, fl.CaseId);
            Assert.Equal(model.WhenMoved.AddSeconds(2).Second, @case.CaseLocations.Last().WhenMoved.Second);
        }

        [Fact]
        public void ShouldDeleteFileRequestBasedOnMaintainFileRequestHistory()
        {
            var f = new FileLocationsTopicUpdaterFixture(Db);
            var @case = new Case().In(Db);

            f.SiteControls.Read<int>(SiteControls.MaintainFileRequestHistory).Returns(0);
            var fileLocation = new TableCodeBuilder().For(TableTypes.FileLocation).Build().In(Db);
            var filePart1 = new CaseFilePart(@case.Id) { FilePart = Fixture.Short(), FilePartTitle = Fixture.String() }.In(Db);

            var fileRequest = new FileRequest
            {
                CaseId = @case.Id,
                FileLocationId = fileLocation.Id,
                FilePartId = filePart1.FilePart,
                DateRequired = Fixture.Date(),
                Status = 0,
                SequenceNo = Fixture.Short()
            }.In(Db);

            @case.FileRequests.Add(fileRequest);

            var saveModel = new FileLocationsSaveModel
            {
                Rows = new[]
                {
                    new FileLocationsData
                    {
                        FilePartId = filePart1.FilePart,
                        FileLocationId = fileLocation.Id,
                        WhenMoved = Fixture.Date(),
                        BayNo = Fixture.String()
                    }
                }
            };

            var saveModelJObject = JObject.FromObject(saveModel);
            f.Subject.UpdateData(saveModelJObject, null, @case);
            Assert.Equal(0, @case.FileRequests.Count);
        }

        [Fact]
        public void ShouldUpdateFileRequestBasedOnMaintainFileRequestHistory()
        {
            var f = new FileLocationsTopicUpdaterFixture(Db);
            var @case = new Case().In(Db);

            f.SiteControls.Read<int>(SiteControls.MaintainFileRequestHistory).Returns(1);
            var fileLocation = new TableCodeBuilder().For(TableTypes.FileLocation).Build().In(Db);
            var filePart1 = new CaseFilePart(@case.Id) { FilePart = Fixture.Short(), FilePartTitle = Fixture.String() }.In(Db);

            var fileRequest = new FileRequest
            {
                CaseId = @case.Id,
                FileLocationId = fileLocation.Id,
                FilePartId = filePart1.FilePart,
                DateRequired = Fixture.Date(),
                Status = 0,
                SequenceNo = Fixture.Short()
            }.In(Db);

            @case.FileRequests.Add(fileRequest);

            var saveModel = new FileLocationsSaveModel
            {
                Rows = new[]
                {
                    new FileLocationsData
                    {
                        FilePartId = filePart1.FilePart,
                        FileLocationId = fileLocation.Id,
                        WhenMoved = Fixture.Date(),
                        BayNo = Fixture.String()
                    }
                }
            };

            var saveModelJObject = JObject.FromObject(saveModel);
            f.Subject.UpdateData(saveModelJObject, null, @case);
            Assert.Equal(1, @case.FileRequests.Count);
            Assert.Equal((short)2, @case.FileRequests.First().Status);
        }

        [Fact]
        public void ShouldDeleteFileLocationsBasedOnMaxLocationSiteControl()
        {
            var f = new FileLocationsTopicUpdaterFixture(Db);
            var @case = new Case().In(Db);
            var fileLocation1 = new TableCodeBuilder().For(TableTypes.FileLocation).Build().In(Db);
            var fileLocation2 = new TableCodeBuilder().For(TableTypes.FileLocation).Build().In(Db);
            var filePart1 = new CaseFilePart(@case.Id) { FilePart = Fixture.Short(), FilePartTitle = Fixture.String() }.In(Db);
            var filePart2 = new CaseFilePart(@case.Id) { FilePart = Fixture.Short(), FilePartTitle = Fixture.String() }.In(Db);
            var caseLocation1 = new CaseLocation(@case, fileLocation1, System.DateTime.Now.AddDays(-3)) { BayNo = Fixture.String(), FilePartId = filePart1.FilePart }.In(Db);
            var caseLocation2 = new CaseLocation(@case, fileLocation1, System.DateTime.Now.AddDays(-2)) { BayNo = Fixture.String(), FilePartId = filePart1.FilePart }.In(Db);
            var caseLocation3 = new CaseLocation(@case, fileLocation1, System.DateTime.Now.AddDays(-1)) { BayNo = Fixture.String(), FilePartId = filePart1.FilePart }.In(Db);
            @case.CaseLocations.Add(caseLocation1);
            @case.CaseLocations.Add(caseLocation2);
            @case.CaseLocations.Add(caseLocation3);
            f.SiteControls.Read<int>(SiteControls.MAXLOCATIONS).Returns(2);

            var saveModel = new FileLocationsSaveModel
            {
                Rows = new[]
                {
                    new FileLocationsData
                    {
                        FilePartId = filePart2.FilePart,
                        FileLocationId = fileLocation2.Id,
                        WhenMoved = System.DateTime.Now,
                        BayNo = Fixture.String(),
                        RowKey = "0"
                    }
                }
            };

            var saveModelJObject = JObject.FromObject(saveModel);
            f.Subject.UpdateData(saveModelJObject, null, @case);
            f.Subject.PostSaveData(saveModelJObject, null, @case);
            Assert.Equal(1, Db.Set<CaseLocation>().Count());
            Assert.Null(Db.Set<CaseLocation>().SingleOrDefault(_ => _.WhenMoved == caseLocation1.WhenMoved));
            Assert.Null(Db.Set<CaseLocation>().SingleOrDefault(_ => _.WhenMoved == caseLocation2.WhenMoved));
        }

        [Fact]
        public void ShouldEditFileLocations()
        {
            var f = new FileLocationsTopicUpdaterFixture(Db);
            var @case = new Case().In(Db);
            var fileLocation1 = new TableCodeBuilder().For(TableTypes.FileLocation).Build().In(Db);
            var fileLocation2 = new TableCodeBuilder().For(TableTypes.FileLocation).Build().In(Db);
            var filePart1 = new CaseFilePart(@case.Id) { FilePart = Fixture.Short(), FilePartTitle = Fixture.String() }.In(Db);
            var filePart2 = new CaseFilePart(@case.Id) { FilePart = Fixture.Short(), FilePartTitle = Fixture.String() }.In(Db);
            var caseLocation = new CaseLocation(@case, fileLocation1, Fixture.Date()) { BayNo = Fixture.String(), FilePartId = filePart1.FilePart }.In(Db);
            @case.CaseLocations.Add(caseLocation);

            var saveModel = new FileLocationsSaveModel
            {
                Rows = new[]
                {
                    new FileLocationsData
                    {
                        FilePartId = filePart2.FilePart,
                        FileLocationId = fileLocation2.Id,
                        WhenMoved = Fixture.Date(),
                        BayNo = Fixture.String(),
                        RowKey = caseLocation.Id.ToString()
                    }
                }
            };

            var saveModelJObject = JObject.FromObject(saveModel);
            f.Subject.UpdateData(saveModelJObject, null, @case);
            var model = saveModel.Rows[0];
            var fl = @case.CaseLocations.First();
            Assert.Equal(model.BayNo, fl.BayNo);
            Assert.Equal(model.FileLocationId, fl.FileLocationId);
            Assert.Equal(model.FilePartId, fl.FilePartId);
        }

        [Fact]
        public void ShouldDeleteFileLocations()
        {
            var f = new FileLocationsTopicUpdaterFixture(Db);
            var @case = new Case().In(Db);
            var fileLocation1 = new TableCodeBuilder().For(TableTypes.FileLocation).Build().In(Db);
            var fileLocation2 = new TableCodeBuilder().For(TableTypes.FileLocation).Build().In(Db);
            var filePart1 = new CaseFilePart(@case.Id) { FilePart = Fixture.Short(), FilePartTitle = Fixture.String() }.In(Db);
            var filePart2 = new CaseFilePart(@case.Id) { FilePart = Fixture.Short(), FilePartTitle = Fixture.String() }.In(Db);
            var caseLocation1 = new CaseLocation(@case, fileLocation1, Fixture.Date()) { BayNo = Fixture.String(), FilePartId = filePart1.FilePart }.In(Db);
            var caseLocation2 = new CaseLocation(@case, fileLocation1, Fixture.Date()) { BayNo = Fixture.String(), FilePartId = filePart1.FilePart }.In(Db);
            @case.CaseLocations.Add(caseLocation1);
            @case.CaseLocations.Add(caseLocation2);

            var saveModel = new FileLocationsSaveModel
            {
                Rows = new[]
                {
                    new FileLocationsData
                    {
                        FilePartId = filePart2.FilePart,
                        FileLocationId = fileLocation2.Id,
                        WhenMoved = Fixture.Date(),
                        BayNo = Fixture.String(),
                        RowKey = caseLocation1.Id.ToString(),
                        Status = KnownModifyStatus.Delete
                    }
                }
            };

            var saveModelJObject = JObject.FromObject(saveModel);
            f.Subject.UpdateData(saveModelJObject, null, @case);
            Assert.Equal(1, Db.Set<CaseLocation>().Count());
            Assert.Equal(caseLocation2.Id, Db.Set<CaseLocation>().First().Id);
        }

        public class FileLocationsTopicUpdaterFixture : IFixture<FileLocationsTopicUpdater>
        {
            public FileLocationsTopicUpdaterFixture(InMemoryDbContext db)
            {
                SiteControls = Substitute.For<ISiteControlReader>();
                Subject = new FileLocationsTopicUpdater(SiteControls, db);
            }

            public FileLocationsTopicUpdater Subject { get; }
            public ISiteControlReader SiteControls { get; set; }
        }
    }
}
