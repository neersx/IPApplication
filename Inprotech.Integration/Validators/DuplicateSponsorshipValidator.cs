using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;

namespace Inprotech.Integration.Validators
{
    public class DuplicateSponsorshipValidator : BaseValidator
    {
        readonly IRepository _repository;

        public DuplicateSponsorshipValidator(IRepository repository)
        {
            _repository = repository;
        }

        protected override bool Validate<T>(T value)
        {
            var model = value as SponsorshipModel;
            if (model == null)
                return false;

            if (_repository.NoDeleteSet<Sponsorship>().Any(s => s.SponsorName == model.SponsorName && s.SponsoredAccount == model.SponsoredEmail))
            {
                this.ValidationResult = new ExecutionResult("duplicate");
                return false;
            }

            return true;
        }
    }
}
