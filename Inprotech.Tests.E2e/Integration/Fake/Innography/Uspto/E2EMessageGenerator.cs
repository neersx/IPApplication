using System;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Tests.E2e.Integration.Fake.Innography.Uspto
{
    class E2EMessageGenerator : MessageGenerator
    {
        readonly PrivatePairE2EController.E2ESession _sessionInfo;

        public E2EMessageGenerator(PrivatePairE2EController.E2ESession sessionInfo)
        {
            _sessionInfo = sessionInfo;
        }

        public override string GeneratedFilePath => $"fake-uspto-e2e\\{_sessionInfo.SessionId}";

        protected override int NumberOfMessagesToGenerate() => _sessionInfo.ApplicationNumbers.Count;

        public override IEnumerable<dynamic> GenerateMessages(string accountId)
        {
            var messages = base.GenerateMessages(accountId).ToList();
            if (_sessionInfo.HasErrors)
            {
                messages.InsertRange(Next(messages.Count), GenerateErrors(accountId));
            }

            return messages;
        }

        protected override (string appId, string appNumber) GetApplicationNumber(int? index = null)
        {
            var appNumber = _sessionInfo.ApplicationNumbers[index.GetValueOrDefault()];
            var appId = appNumber.Replace("/", string.Empty).Replace(",", string.Empty);

            return (appId, appNumber);
        }

        IEnumerable<dynamic> GenerateErrors(string accountId)
        {
            var services = GetTopRecentlyCreatedServices(3);

            var numberOfMessages = NumberOfMessagesToGenerate();
            for (var i = 0; i < numberOfMessages; i++)
            {
                var s = services.ElementAt(Next(services.Count));
                var serviceId = s.Key;

                yield return new
                {
                    meta = new
                    {
                        service_id = serviceId,
                        service_type = "uspto",
                        event_date = DateTime.Today.ToString("yyyy-MM-dd"),
                        status = "error",
                        message = "401 - Authentication Error"
                    },
                    links = new
                    {
                    }
                };
            }
        }
    }
}