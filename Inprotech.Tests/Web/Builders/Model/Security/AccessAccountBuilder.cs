using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Web.Builders.Model.Security
{
    public class AccessAccountBuilder : IBuilder<AccessAccount>
    {
        public int? AccountId { get; set; }
        public string AccountName { get; set; }
        public bool IsInternal { get; set; }

        public AccessAccount Build()
        {
            return new AccessAccount(
                                     AccountId ?? Fixture.Integer(),
                                     AccountName ?? Fixture.String()
                                    );
        }

        public static AccessAccountBuilder AsInternalAccount(int accountId, string accountName)
        {
            return new AccessAccountBuilder
            {
                AccountId = accountId,
                AccountName = accountName,
                IsInternal = true
            };
        }

        public static AccessAccountBuilder AsExternalAccount(int accountId, string accountName)
        {
            return new AccessAccountBuilder
            {
                AccountId = accountId,
                AccountName = accountName,
                IsInternal = false
            };
        }
    }
}