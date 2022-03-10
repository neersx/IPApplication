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
using Inprotech.Web.Configuration.DMSIntegration;
using Inprotech.Web.Names.Details;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;

namespace Inprotech.Tests.Web.Names.Details
{
    public class NameDocumentManagementControllerFacts
    {
        readonly INameDmsFolders _dmsFolders = Substitute.For<INameDmsFolders>();
        readonly IDmsEventSink _dmsEventSink = Substitute.For<IDmsEventSink>();
        readonly ILogger<NameDocumentManagementController> _logger = Substitute.For<ILogger<NameDocumentManagementController>>();
        readonly IDmsTestDocuments _dmsTestDocuments = Substitute.For<IDmsTestDocuments>();
        NameDocumentManagementController CreateSubject()
        {
            return new NameDocumentManagementController(_dmsFolders, _dmsEventSink, _logger, _dmsTestDocuments);
        }

        [Fact]
        public void SecureByAccessDmsTaskSecurity()
        {
            var r = TaskSecurity.Secures<NameDocumentManagementController>(ApplicationTask.AccessDocumentsfromDms);

            Assert.True(r);
        }

        [Fact]
        public async Task ShouldCallGetTopFolderService()
        {
            var nameId = Fixture.Integer();

            var folders = new[]
            {
                new DmsFolder(), new DmsFolder()
            };

            _dmsFolders.FetchTopFolders(nameId).Returns(folders);
            _dmsEventSink.GetEvents(Arg.Any<Status>(), Arg.Any<string[]>()).Returns(new List<DocumentManagementEvent>()
            {
                new DocumentManagementEvent() { Key = "testKey1"},
                new DocumentManagementEvent() { Key = "testKey2"}
            });
            var subject = CreateSubject();
            var r = await subject.GetTopFolders(nameId);

            await _dmsFolders.Received(1).FetchTopFolders(nameId);

            Assert.Equal(r.Folders, folders);
            Assert.Equal(2, r.Errors.Count());
        }

        [Fact]
        public async Task ShouldReturnErrorIfException()
        {
            var nameId = Fixture.Integer();

            _dmsFolders.FetchTopFolders(nameId).Throws(new Exception());
            _dmsEventSink.GetEvents(Arg.Any<Status>(), Arg.Any<string[]>()).Returns(new List<DocumentManagementEvent>()
            {
                new DocumentManagementEvent(){ Key = "testKey1"},
                new DocumentManagementEvent(){ Key = "testKey2"}
            });
            var subject = CreateSubject();
            var r = await subject.GetTopFolders(nameId);

            await _dmsFolders.Received(1).FetchTopFolders(nameId);

            _logger.Received(1).Exception(Arg.Any<Exception>());
            Assert.Null(r.Folders);
            Assert.Equal(1, r.Errors.Count());
            Assert.Equal(KnownDocumentManagementEvents.FailedConnection, r.Errors.Single());
        }

        [Fact]
        public async Task ShouldReturnErrorIfArgumentException()
        {
            var nameId = Fixture.Integer();

            _dmsFolders.FetchTopFolders(nameId).Throws(new ArgumentException());
            _dmsEventSink.GetEvents(Arg.Any<Status>(), Arg.Any<string[]>()).Returns(new List<DocumentManagementEvent>()
            {
                new DocumentManagementEvent(){ Key = "testKey1"},
                new DocumentManagementEvent(){ Key = "testKey2"}
            });
            var subject = CreateSubject();
            var r = await subject.GetTopFolders(nameId);

            await _dmsFolders.Received(1).FetchTopFolders(nameId);

            _logger.Received(1).Exception(Arg.Any<Exception>());
            Assert.Null(r.Folders);
            Assert.Equal(2, r.Errors.Count());
        }

        [Fact]
        public async Task ShouldReturnErrorIfAuthenticationException()
        {
            var nameId = Fixture.Integer();

            _dmsFolders.FetchTopFolders(nameId).Throws(new AuthenticationException());
            _dmsEventSink.GetEvents(Arg.Any<Status>(), Arg.Any<string[]>()).Returns(new List<DocumentManagementEvent>()
            {
                new DocumentManagementEvent(){ Key = "testKey1"},
                new DocumentManagementEvent(){ Key = "testKey2"}
            });
            var subject = CreateSubject();
            var r = await subject.GetTopFolders(nameId);

            await _dmsFolders.Received(1).FetchTopFolders(nameId);

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
            var r = await subject.TestNameFolders(caseId, settings);

            await _dmsTestDocuments.Received(1).TestConnection(Arg.Any<ConnectionTestRequestModel>());
            await _dmsFolders.Received(0).FetchTopFolders(caseId, Arg.Any<IManageTestSettings>());

            Assert.Equal(2, r.Errors.Count());
            Assert.Equal("Error1", r.Errors.First());
        }

        [Fact]
        public async Task ShouldCallFetchFoldersForTestDocuments()
        {
            var nameKey = Fixture.Integer();

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
                Results = new List<DocumentManagementEvent>
                {
                    new DocumentManagementEvent {Status = Status.Info, Key = "Key1", NameType = "value1"}
                }
            };

            var folders = new[]
            {
                new DmsFolder(), new DmsFolder()
            };

            var testSettings = new IManageTestSettings();

            _dmsTestDocuments.TestConnection(Arg.Any<ConnectionTestRequestModel>()).Returns(response);
            _dmsTestDocuments.ManageTestSettings(settings).Returns(testSettings);
            _dmsFolders.FetchTopFolders(nameKey, Arg.Any<IManageTestSettings>()).Returns(folders);
            _dmsTestDocuments.GetDmsEventsForTest().Returns(response);

            var subject = CreateSubject();
            var r = await subject.TestNameFolders(nameKey, settings);

            await _dmsTestDocuments.Received(1).TestConnection(Arg.Any<ConnectionTestRequestModel>());
            _dmsTestDocuments.Received(1).ManageTestSettings(settings);
            await _dmsFolders.Received(1).FetchTopFolders(nameKey, testSettings);

            Assert.Equal(1, r.Results.Count());
            Assert.NotNull(r.SearchParams);
        }

        [Fact]
        public async Task ShouldThrowErrorsForTestDocumentsForAuthException()
        {
            var nameKey = Fixture.Integer();

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
            _dmsFolders.FetchTopFolders(nameKey, Arg.Any<IManageTestSettings>()).Throws(new AuthenticationException());
            _dmsTestDocuments.GetDmsSearchParamsForTest().Returns(response);
            _dmsEventSink.GetEvents(Arg.Any<Status>(), Arg.Any<string[]>()).Returns(new List<DocumentManagementEvent>
            {
                new DocumentManagementEvent{ Status = Status.Error, Key = "testKey1"},
                new DocumentManagementEvent{ Status = Status.Error, Key = "testKey2"}
            });

            var subject = CreateSubject();
            var r = await subject.TestNameFolders(nameKey, settings);

            await _dmsTestDocuments.Received(1).TestConnection(Arg.Any<ConnectionTestRequestModel>());
            await _dmsFolders.Received(1).FetchTopFolders(nameKey, Arg.Any<IManageTestSettings>());

            Assert.Equal(1, r.SearchParams.Count());
            Assert.Equal(2, r.Errors.Count());
        }
    }
}