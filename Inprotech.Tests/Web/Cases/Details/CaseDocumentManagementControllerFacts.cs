using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.DmsIntegration.Component;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.Configuration.DMSIntegration;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseDocumentManagementControllerFacts
    {
        readonly ICaseDmsFolders _dmsFolders = Substitute.For<ICaseDmsFolders>();
        readonly IDmsEventSink _eventSink = Substitute.For<IDmsEventSink>();
        readonly ILogger<CaseDocumentManagementController> _logger = Substitute.For<ILogger<CaseDocumentManagementController>>();
        readonly IDmsTestDocuments _dmsTestDocuments = Substitute.For<IDmsTestDocuments>();
        CaseDocumentManagementController CreateSubject()
        {
            return new CaseDocumentManagementController(_dmsFolders, _eventSink, _logger, _dmsTestDocuments);
        }

        [Fact]
        public void SecureByAccessDmsTaskSecurity()
        {
            var r = TaskSecurity.Secures<CaseDocumentManagementController>(ApplicationTask.AccessDocumentsfromDms);

            Assert.True(r);
        }

        [Fact]
        public async Task ShouldCallGetTopFolderService()
        {
            var caseId = Fixture.Integer();

            var folders = new[]
            {
                new DmsFolder(), new DmsFolder()
            };

            _dmsFolders.FetchTopFolders(caseId).Returns(folders);

            _eventSink.GetEvents(Arg.Any<Status>(), Arg.Any<string[]>()).Returns(new List<DocumentManagementEvent>()
            {
                new DocumentManagementEvent() { Key = "testKey1"},
                new DocumentManagementEvent() { Key = "testKey2"}
            });
            var subject = CreateSubject();
            var r = await subject.GetTopFolders(caseId);

            await _dmsFolders.Received(1).FetchTopFolders(caseId);

            Assert.Equal(r.Folders, folders);
            Assert.Equal(2, r.Errors.Count());
        }

        [Fact]
        public async Task ShouldReturnErrorIfException()
        {
            var caseId = Fixture.Integer();

            _dmsFolders.FetchTopFolders(caseId).Throws(new Exception());
            _eventSink.GetEvents(Arg.Any<Status>(), Arg.Any<string[]>()).Returns(new List<DocumentManagementEvent>()
            {
                new DocumentManagementEvent(){ Key = "testKey1"},
                new DocumentManagementEvent(){ Key = "testKey2"}
            });
            var subject = CreateSubject();
            var r = await subject.GetTopFolders(caseId);

            await _dmsFolders.Received(1).FetchTopFolders(caseId);

            _logger.Received(1).Exception(Arg.Any<Exception>());
            Assert.Null(r.Folders);
            Assert.Equal(1, r.Errors.Count());
            Assert.Equal(KnownDocumentManagementEvents.FailedConnection, r.Errors.Single());
        }

        [Fact]
        public async Task ShouldReturnErrorIfArgumentException()
        {
            var caseId = Fixture.Integer();

            _dmsFolders.FetchTopFolders(caseId).Throws(new ArgumentException());
            _eventSink.GetEvents(Arg.Any<Status>(), Arg.Any<string[]>()).Returns(new List<DocumentManagementEvent>()
            {
                new DocumentManagementEvent(){ Key = "testKey1"},
                new DocumentManagementEvent(){ Key = "testKey2"}
            });
            var subject = CreateSubject();
            var r = await subject.GetTopFolders(caseId);

            await _dmsFolders.Received(1).FetchTopFolders(caseId);

            _logger.Received(1).Exception(Arg.Any<Exception>());
            Assert.Null(r.Folders);
            Assert.Equal(2, r.Errors.Count());
        }

        [Fact]
        public async Task ShouldReturnErrorIfAuthenticationException()
        {
            var caseId = Fixture.Integer();
            
            _dmsFolders.FetchTopFolders(caseId).Throws(new AuthenticationException());
            _eventSink.GetEvents(Arg.Any<Status>(), Arg.Any<string[]>()).Returns(new List<DocumentManagementEvent>()
            {
                new DocumentManagementEvent(){ Key = "testKey1"},
                new DocumentManagementEvent(){ Key = "testKey2"}
            });
            var subject = CreateSubject();
            var r = await subject.GetTopFolders(caseId);

            await _dmsFolders.Received(1).FetchTopFolders(caseId);

            _logger.Received(1).Exception(Arg.Any<Exception>());
            Assert.Null(r.Folders);
            Assert.Equal(2, r.Errors.Count());
        }

        [Fact]
        public async Task ShouldCallTestConnectionForTestDocuments()
        {
            var caseId = Fixture.Integer();

            var settings = new SettingsController.DmsModel
            {
                Username = Fixture.String(),
                Password = Fixture.String(),
                IManageSettings = new IManageSettingsModel()
            };

            var response = new DmsFolderTestResponse
            {
                IsConnectionUnsuccessful = true,
                Errors = new List<string> { "Error1", "Error2"}
            };

            _dmsTestDocuments.TestConnection(Arg.Any<ConnectionTestRequestModel>()).Returns(response);
           
            var subject = CreateSubject();
            var r = await subject.TestCaseFolders(caseId, settings);

            await _dmsTestDocuments.Received(1).TestConnection(Arg.Any<ConnectionTestRequestModel>());
            await _dmsFolders.Received(0).FetchTopFolders(caseId, Arg.Any<IManageTestSettings>());

            Assert.Equal(2, r.Errors.Count());
            Assert.Equal("Error1", r.Errors.First());
        }

        [Fact]
        public async Task ShouldCallFetchFoldersForTestDocuments()
        {
            var caseId = Fixture.Integer();

            var settings = new SettingsController.DmsModel
            {
                Username = Fixture.String(),
                Password = Fixture.String(),
                IManageSettings = new IManageSettingsModel()
            };

            var response = new DmsFolderTestResponse
            {
                IsConnectionUnsuccessful = false,
                SearchParams = new List<DmsSearchParams>(),
                Results = new List<DocumentManagementEvent> { new DocumentManagementEvent(Status.Info, "Key1", "value1")}
            };

            var folders = new[]
            {
                new DmsFolder(), new DmsFolder()
            };

            var testSettings = new IManageTestSettings();

            _dmsTestDocuments.TestConnection(Arg.Any<ConnectionTestRequestModel>()).Returns(response);
            _dmsTestDocuments.ManageTestSettings(settings).Returns(testSettings);
            _dmsFolders.FetchTopFolders(caseId, Arg.Any<IManageTestSettings>()).Returns(folders);
            _dmsTestDocuments.GetDmsEventsForTest().Returns(response);

            var subject = CreateSubject();
            var r = await subject.TestCaseFolders(caseId, settings);

            await _dmsTestDocuments.Received(1).TestConnection(Arg.Any<ConnectionTestRequestModel>());
            _dmsTestDocuments.Received(1).ManageTestSettings(settings);
            await _dmsFolders.Received(1).FetchTopFolders(caseId, testSettings);

            Assert.Equal(1, r.Results.Count());
            Assert.NotNull(r.SearchParams);
        }

        [Fact]
        public async Task ShouldThrowErrorsForTestDocumentsForAuthException()
        {
            var caseId = Fixture.Integer();

            var settings = new SettingsController.DmsModel
            {
                Username = Fixture.String(),
                Password = Fixture.String(),
                IManageSettings = new IManageSettingsModel()
            };

            var response = new List<DmsSearchParams>
            {
                new DmsSearchParams {Key ="key1", Value = "value1"}
            };

            _dmsTestDocuments.TestConnection(Arg.Any<ConnectionTestRequestModel>()).Returns(new DmsFolderTestResponse() { Errors = new List<string>()});
            _dmsFolders.FetchTopFolders(caseId, Arg.Any<IManageTestSettings>()).Throws(new AuthenticationException());
            _dmsTestDocuments.GetDmsSearchParamsForTest().Returns(response);
            _eventSink.GetEvents(Arg.Any<Status>(), Arg.Any<string[]>()).Returns(new List<DocumentManagementEvent>
            {
                new DocumentManagementEvent{ Status = Status.Error, Key = "testKey1"},
                new DocumentManagementEvent{ Status = Status.Error, Key = "testKey2"}
            });

            var subject = CreateSubject();
            var r = await subject.TestCaseFolders(caseId, settings);

            await _dmsTestDocuments.Received(1).TestConnection(Arg.Any<ConnectionTestRequestModel>());
            await _dmsFolders.Received(1).FetchTopFolders(caseId, Arg.Any<IManageTestSettings>());

            Assert.Equal(1, r.SearchParams.Count());
            Assert.Equal(2, r.Errors.Count());
        }
    }
}