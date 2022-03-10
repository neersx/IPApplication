using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Notifications;
using Inprotech.IntegrationServer.PtoAccess.Innography.Activities;
using Inprotech.Tests.Web;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography.Activities
{
    public class NotificationReviewStatusModifierFacts : FactBase
    {
        const string HighMatchSample = "{\"ipid\":\"String1743082616\",\"client_index\":\"378222458\",\"application_number\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"AU19900065827\",\"public_data\":\"AU19900065827\"},\"application_date\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"1989-11-14\",\"public_data\":\"1989-11-14\"},\"publication_number\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"AU635979B2\",\"public_data\":\"AU635979B2\"},\"publication_date\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"1989-11-14\",\"public_data\":\"1989-11-14\"},\"grant_number\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"1989-11-14\",\"public_data\":\"1989-11-14\"},\"grant_date\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"1989-11-14\",\"public_data\":\"1989-11-14\"},\"type_code\":null,\"country_code\":null,\"country_name\":null,\"title\":null,\"inventors\":null}";
        const string HighMatchTradeMarkSample = "{\"ipid\":\"String1743082616\",\"client_index\":\"378222458\",\"application_number\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"AU19900065827\",\"public_data\":\"AU19900065827\"},\"application_date\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"1989-11-14\",\"public_data\":\"1989-11-14\"},\"publication_number\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"AU635979B2\",\"public_data\":\"AU635979B2\"},\"publication_date\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"1989-11-14\",\"public_data\":\"1989-11-14\"},\"registration_number\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"1989-11-14\",\"public_data\":\"1989-11-14\"},\"registration_date\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"1989-11-14\",\"public_data\":\"1989-11-14\"},\"type_code\":null,\"country_code\":null,\"country_name\":null,\"title\":null,\"inventors\":null}";
        const string MediumMatchSample = "{\"ipid\":\"String1743082616\",\"client_index\":\"378222458\",\"application_number\":{\"message\":\"VERIFICATION_FAILURE\",\"status_code\":\"01\",\"input\":\"AU19900065827\",\"public_data\":\"AU19900065827\"},\"application_date\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"1989-11-14\",\"public_data\":\"1989-11-14\"},\"publication_number\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"AU635979B2\",\"public_data\":\"AU635979B2\"},\"publication_date\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"1989-11-14\",\"public_data\":\"1989-11-14\"},\"grant_number\":{\"message\":\"VERIFICATION_FAILURE\",\"status_code\":\"21\",\"input\":\"1989-12-14\",\"public_data\":\"1989-11-14\"},\"grant_date\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"1989-11-14\",\"public_data\":\"1989-11-14\"},\"type_code\":null,\"country_code\":null,\"country_name\":null,\"title\":null,\"inventors\":null}";
        const string LowMatchSample = "{\"ipid\":\"String1743082616\",\"client_index\":\"378222458\",\"application_number\":{\"message\":\"VERIFICATION_FAILURE\",\"status_code\":\"21\",\"input\":\"AU19900065827\",\"public_data\":\"AU19900065820\"},\"application_date\":{\"message\":\"VERIFICATION_FAILURE\",\"status_code\":\"21\",\"input\":\"1989-12-14\",\"public_data\":\"1989-11-14\"},\"publication_number\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"AU635979B2\",\"public_data\":\"AU635979B2\"},\"publication_date\":{\"message\":\"VERIFICATION_FAILURE\",\"status_code\":\"21\",\"input\":\"1989-11-14\",\"public_data\":\"1989-12-14\"},\"grant_number\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"1989-11-14\",\"public_data\":\"1989-11-14\"},\"grant_date\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"1989-11-14\",\"public_data\":\"1989-11-14\"},\"type_code\":null,\"country_code\":null,\"country_name\":null,\"title\":null,\"inventors\":null}";
        const string MediumMatchTradeMarkSample = "{\"ipid\":\"String1743082616\",\"client_index\":\"378222458\",\"application_number\":{\"message\":\"VERIFICATION_FAILURE\",\"status_code\":\"24\",\"input\":\"AU19900065827\",\"public_data\":\"AU19900065827\"},\"application_date\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"1989-11-14\",\"public_data\":\"1989-11-14\"},\"publication_number\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"20\",\"input\":\"AU635979B2\",\"public_data\":\"AU635979B2\"},\"publication_date\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"1989-11-14\",\"public_data\":\"1989-11-14\"},\"registration_number\":{\"message\":\"VERIFICATION_FAILURE\",\"status_code\":\"21\",\"input\":\"1989-12-14\",\"public_data\":\"1989-11-14\"},\"registration_date\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"1989-11-14\",\"public_data\":\"1989-11-14\"},\"type_code\":null,\"country_code\":null,\"country_name\":null,\"title\":null,\"inventors\":null}";
        const string LowMatchTradeMarkSample = "{\"ipid\":\"String1743082616\",\"client_index\":\"378222458\",\"application_number\":{\"message\":\"VERIFICATION_FAILURE\",\"status_code\":\"22\",\"input\":\"AU19900065827\",\"public_data\":\"AU19900065820\"},\"application_date\":{\"message\":\"VERIFICATION_FAILURE\",\"status_code\":\"21\",\"input\":\"1989-12-14\",\"public_data\":\"1989-11-14\"},\"publication_number\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"22\",\"input\":\"AU635979B2\",\"public_data\":\"AU635979B2\"},\"publication_date\":{\"message\":\"VERIFICATION_FAILURE\",\"status_code\":\"21\",\"input\":\"1989-11-14\",\"public_data\":\"1989-12-14\"},\"registration_number\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"1989-11-14\",\"public_data\":\"1989-11-14\"},\"registration_date\":{\"message\":\"VERIFICATION_SUCCESS\",\"status_code\":\"01\",\"input\":\"1989-11-14\",\"public_data\":\"1989-11-14\"},\"type_code\":null,\"country_code\":null,\"country_name\":null,\"title\":null,\"inventors\":null}";

        readonly ISecurityContext _securityContext = Substitute.For<ISecurityContext>();

        [Theory]
        [InlineData(KnownPropertyTypes.Patent, LowMatchSample)]
        [InlineData(KnownPropertyTypes.Patent, MediumMatchSample)]
        [InlineData(KnownPropertyTypes.TradeMark, LowMatchTradeMarkSample)]
        [InlineData(KnownPropertyTypes.TradeMark, MediumMatchTradeMarkSample)]
        public void LeaveNotificationAsCreated(string propertyTpe, string sample)
        {
            var backgroundUser = new User().WithKnownId(Fixture.Integer());
            _securityContext.User.Returns(backgroundUser);
            var subject = new NotificationReviewStatusModifier(_securityContext);
            var n = subject.Modify(new CaseNotification(), new DataDownload
            {
                Case = new EligibleCase {PropertyType = propertyTpe},
                AdditionalDetails = sample
            });

            Assert.Null(n.ReviewedBy);
            Assert.False(n.IsReviewed);
        }

        [Theory]
        [InlineData(KnownPropertyTypes.Patent, HighMatchSample)]
        [InlineData(KnownPropertyTypes.TradeMark, HighMatchTradeMarkSample)]
        public void ChangesNotificationToReviewedStatus(string propertyType, string sample)
        {
            var caseKey = Fixture.Integer();

            var backgroundUser = new User().WithKnownId(Fixture.Integer());

            _securityContext.User.Returns(backgroundUser);

            var subject = new NotificationReviewStatusModifier(_securityContext);
            var n = subject.Modify(new CaseNotification(), new DataDownload
            {
                Case = new EligibleCase
                {
                    CaseKey = caseKey,
                    PropertyType = propertyType
                },
                AdditionalDetails = sample
            });

            Assert.Equal(backgroundUser.Id, n.ReviewedBy);
            Assert.True(n.IsReviewed);
        }
    }
}