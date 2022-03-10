using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Configuration.DMSIntegration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.DocumentManagement
{
    public class DmsTestDocumentsFacts : FactBase
    {
        readonly IDmsEventSink _eventSink = Substitute.For<IDmsEventSink>();
        readonly ISettingTester _settingTester = Substitute.For<ISettingTester>();
        readonly IPreferredCultureResolver _cultureResolver = Substitute.For<IPreferredCultureResolver>();
        DmsTestDocuments CreateSubject()
        {
            _cultureResolver.Resolve().Returns("en");
            return new DmsTestDocuments(Db, _eventSink, _settingTester, _cultureResolver);
        }

        [Fact]
        public async Task ShowCallTestConnection()
        {
            var settings = new ConnectionTestRequestModel()
            {
                UserName = Fixture.String(),
                Password = Fixture.String(),
                Settings = new List<IManageSettings.SiteDatabaseSettings>()
            };
            var response = new List<ConnectionResponseModel>
            {
                new ConnectionResponseModel {Success = true, ErrorMessages = new List<string>()},
                new ConnectionResponseModel {ErrorMessages = new List<string> {"Error1"}}
            };
            _settingTester.TestConnections(Arg.Any<ConnectionTestRequestModel>()).Returns(response);

            var subject = CreateSubject();
            var r = await subject.TestConnection(settings);

            await _settingTester.Received(1).TestConnections(Arg.Any<ConnectionTestRequestModel>());

            Assert.False(r.IsConnectionUnsuccessful);
            Assert.Equal(1,r.Errors.Count());
            Assert.Equal("Error1", r.Errors.First());
        }

        [Fact]
        public async Task CallTestConnectionReturnsErrors()
        {
            var settings = new ConnectionTestRequestModel
            {
                UserName = Fixture.String(),
                Password = Fixture.String(),
                Settings = new List<IManageSettings.SiteDatabaseSettings>()
            };
            var response = new List<ConnectionResponseModel>
            {
                new ConnectionResponseModel {ErrorMessages = new List<string> {"Error1"}},
                new ConnectionResponseModel {ErrorMessages = new List<string> {"Error2"}}
            };
            _settingTester.TestConnections(Arg.Any<ConnectionTestRequestModel>()).Returns(response);

            var subject = CreateSubject();
            var r = await subject.TestConnection(settings);

            await _settingTester.Received(1).TestConnections(Arg.Any<ConnectionTestRequestModel>());

            Assert.True(r.IsConnectionUnsuccessful);
            Assert.Equal(2,r.Errors.Count());
            Assert.Equal("Error1", r.Errors.First());
        }

        [Fact]
        public async Task GetResultEventsForTest()
        {
            var nt = new NameTypeBuilder().Build().In(Db);
            var folder1 = Fixture.String();
            var folder2 = Fixture.String();
            _eventSink.GetNameTypes().Returns(new List<string> {nt.NameTypeCode});
            _eventSink.GetEvents(Arg.Any<Status>(), Arg.Any<string[]>()).Returns(new List<DocumentManagementEvent>
            {
                new DocumentManagementEvent { Status = Status.Info, Key = KnownDocumentManagementEvents.CaseWorkspace, Value = folder1},
                new DocumentManagementEvent { Status = Status.Info, Key = KnownDocumentManagementEvents.NameWorkspace, NameType = nt.NameTypeCode, Value = folder2}
            });

            var subject = CreateSubject();
            var r = await subject.GetDmsEventsForTest();
            Assert.Equal(2, r.Results.Count());
            Assert.Equal(folder1, r.Results.First().Value);
            Assert.Equal(nt.Name, r.Results.Last().NameType);
        }

        [Fact]
        public async Task GetSearchParamsForTest()
        {
            var nt = new NameTypeBuilder().Build().In(Db);
            var field1 = Fixture.String();
            var field2 = Fixture.String();
            _eventSink.GetNameTypes().Returns(new List<string> {nt.NameTypeCode});
            _eventSink.GetEvents(Arg.Any<Status>(), Arg.Any<string[]>()).Returns(new List<DocumentManagementEvent>
            {
                new DocumentManagementEvent { Status = Status.Info, Key = KnownDocumentManagementEvents.CaseWorkspaceCustomField1, Value = field1},
                new DocumentManagementEvent { Status = Status.Info, Key = KnownDocumentManagementEvents.NameWorkspaceCustomField1, NameType = nt.NameTypeCode, Value = field2}
            });

            var subject = CreateSubject();
            var r = await subject.GetDmsSearchParamsForTest();
            var dmsSearchParamses = r as DmsSearchParams[] ?? r.ToArray();
            Assert.Equal(2, dmsSearchParamses.Count());
            Assert.Equal(field1, dmsSearchParamses.First().Value);
            Assert.Equal(nt.Name, dmsSearchParamses.Last().NameType);
        }
    }
}
