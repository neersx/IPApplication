using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Exceptions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.DmsIntegration.Component;
using Inprotech.Web.Configuration.DMSIntegration;
using Inprotech.Web.DocumentManagement;

namespace Inprotech.Web.Names.Details
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.AccessDocumentsfromDms)]
    [RoutePrefix("api/name")]
    public class NameDocumentManagementController : ApiController
    {
        readonly IDmsEventSink _dmsEventSink;
        readonly INameDmsFolders _dmsFolders;
        readonly ILogger<NameDocumentManagementController> _logger;
        readonly IDmsTestDocuments _dmsTestDocuments;

        public NameDocumentManagementController(INameDmsFolders dmsFolders, IDmsEventSink dmsEventSink, ILogger<NameDocumentManagementController> logger,
                                                IDmsTestDocuments dmsTestDocuments)
        {
            _dmsFolders = dmsFolders;
            _dmsEventSink = dmsEventSink;
            _logger = logger;
            _dmsTestDocuments = dmsTestDocuments;
        }

        [HttpGet]
        [RequiresNameAuthorization]
        [Route("{nameKey:int}/document-management/folders")]
        [HandleException(typeof(OAuth2TokenException), typeof(HandleOAuthExceptions))]
        public async Task<DmsFolderResponse> GetTopFolders(int nameKey)
        {
            try
            {
                var folders = await _dmsFolders.FetchTopFolders(nameKey);
                return new DmsFolderResponse
                {
                    Folders = folders,
                    Errors = GetErrors()
                };
            }
            catch (OAuth2TokenException)
            {
                throw;
            }
            catch (Exception e)
            {
                _logger.Exception(e);
                if (e is ArgumentException || e is AuthenticationException || e is DmsConfigurationException)
                {
                    return new DmsFolderResponse
                    {
                        Errors = GetErrors()
                    };
                }

                return new DmsFolderResponse
                {
                    Errors = new[] { KnownDocumentManagementEvents.FailedConnection }
                };
            }
        }

        IEnumerable<string> GetErrors()
        {
            var errorEventsRequired = new[]
            {
                KnownDocumentManagementEvents.MissingLoginPreference,
                KnownDocumentManagementEvents.FailedLoginOrPasswordPreferences,
                KnownDocumentManagementEvents.FailedConnection,
                KnownDocumentManagementEvents.IncompleteConfiguration,
                KnownDocumentManagementEvents.FailedConnectionIfImpersonationAuthenticationFailure
            };

            return _dmsEventSink.GetEvents(Status.Error, errorEventsRequired).ToList().Select(_ => _.Key).Distinct();
        }

        [HttpPost]
        [RequiresNameAuthorization]
        [Route("testNameFolders/{nameKey:int}")]
        public async Task<DmsFolderTestResponse> TestNameFolders(int nameKey, SettingsController.DmsModel model)
        {
            try
            {
                var settings = new ConnectionTestRequestModel { UserName = model.Username, Password = model.Password, Settings = model.IManageSettings.Databases };
                var connectionResponse = await _dmsTestDocuments.TestConnection(settings);
                if (connectionResponse.IsConnectionUnsuccessful) return new DmsFolderTestResponse { Errors = connectionResponse.Errors };

                var testSettings = _dmsTestDocuments.ManageTestSettings(model);

                await _dmsFolders.FetchTopFolders(nameKey, testSettings);

                var response = await _dmsTestDocuments.GetDmsEventsForTest();

                response.Errors = connectionResponse.Errors;

                return response;
            }
            catch (Exception e)
            {
                var dmsResponse = new DmsFolderTestResponse();
                if (e is ArgumentException || e is AuthenticationException)
                {
                    dmsResponse.Errors = GetErrors();
                }
                else if (e is DmsConfigurationException)
                {
                    dmsResponse.Errors = new[] { e.Message };
                }
                else
                {
                    dmsResponse.Errors = new[] { KnownDocumentManagementEvents.FailedConnection };
                }

                dmsResponse.SearchParams = await _dmsTestDocuments.GetDmsSearchParamsForTest();

                return dmsResponse;
            }
        }
    }
}