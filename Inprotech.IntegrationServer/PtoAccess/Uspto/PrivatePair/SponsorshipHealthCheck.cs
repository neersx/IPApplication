using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public interface ISponsorshipHealthCheck
    {
        void CheckErrors(Message message);

        Task SetSponsorshipStatus();
    }

    class SponsorshipHealthCheck : ISponsorshipHealthCheck
    {
        readonly string[] AuthErrorMessageStart =
        {
            "40",
            "500 : no cookies, unexpectedly empty java response"
        };
        readonly IRepository _repository;
        readonly Dictionary<string, SponsorshipStatusData> _serviceIds = new Dictionary<string, SponsorshipStatusData>();

        public SponsorshipHealthCheck(IRepository repository)
        {
            _repository = repository;
        }

        public void CheckErrors(Message message)
        {
            if (message?.Meta == null)
                return;
            if (HandledSuccessful(message)) return;
            HandledAuthError(message);
        }

        bool HandledSuccessful(Message message)
        {
            if (message.Meta.Status == "success")
            {
                if (_serviceIds.TryGetValue(message.Meta.ServiceId, out var service))
                    SetServiceStatus(message.Meta, service, SponsorshipStatus.Active);
                else
                    _serviceIds.Add(message.Meta.ServiceId, new SponsorshipStatusData(SponsorshipStatus.Active, message.Meta.EventDateParsed));
                return true;
            }

            return false;
        }

        bool HandledAuthError(Message message)
        {
            if (message.Meta.Status == "error" && AuthErrorMessageStart.Any(_ => message.Meta.Message?.StartsWith(_) ?? false))
            {
                if (_serviceIds.TryGetValue(message.Meta.ServiceId, out var service))
                    SetServiceStatus(message.Meta, service, SponsorshipStatus.Error, message.Meta.Message);
                else
                    _serviceIds.Add(message.Meta.ServiceId, new SponsorshipStatusData(SponsorshipStatus.Error, message.Meta.EventDateParsed, message.Meta.Message));
                return true;
            }

            return false;
        }

        void SetServiceStatus(Meta meta, SponsorshipStatusData service, SponsorshipStatus status, string message = null)
        {
            if (meta.EventDateParsed >= service.EventDate)
            {
                service.Status = status;
                service.EventDate = meta.EventDateParsed;
                service.Message = message;
            }
        }

        public async Task SetSponsorshipStatus()
        {
            var sponsorships = await _repository.NoDeleteSet<Sponsorship>().Where(_ => _serviceIds.Keys.Contains(_.ServiceId)).ToArrayAsync();
            foreach (var sponsorship in sponsorships)
            {
                var service = _serviceIds[sponsorship.ServiceId];
                if (service.Status != sponsorship.Status && service.EventDate >= sponsorship.StatusDate)
                {
                    sponsorship.Status = service.Status;
                    sponsorship.StatusDate = service.EventDate;
                    sponsorship.StatusMessage = service.Message;
                }
            }
            if (sponsorships.Any())
                await _repository.SaveChangesAsync();
        }

        public class SponsorshipStatusData
        {
            public SponsorshipStatusData(SponsorshipStatus status, DateTime eventDate, string message = null)
            {
                Status = status;
                EventDate = eventDate;
                Message = message;
            }

            public DateTime EventDate { get; set; }

            public SponsorshipStatus Status { get; set; }

            public string Message { get; set; }
        }
    }
}