using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Integration.Validators
{
    public class DuplicateCustomerNumberValidator : BaseValidator
    {
        readonly IRepository _repository;

        public DuplicateCustomerNumberValidator(IRepository repository)
        {
            _repository = repository;
        }

        protected override bool Validate<T>(T value)
        {
            var model = value as SponsorshipModel;
            if (model == null)
                return false;

            if (DuplicateNumbers(model.CustomerNumbers).Any())
            {
                ValidationResult = new ExecutionResult("duplicateCustomerNumber");
                return false;
            }

            var customerNumbers = GetSplitCustomerNumbers(new[] { model.CustomerNumbers });
            var baseSponsorships = string.IsNullOrWhiteSpace(model.ServiceId)
                ? _repository.NoDeleteSet<Sponsorship>()
                : _repository.NoDeleteSet<Sponsorship>().Where(s => s.ServiceId != model.ServiceId);
            var exitingCustomerNumbers = GetSplitCustomerNumbers(baseSponsorships
                                                                   .Select(_ => _.CustomerNumbers).ToArray());

            var intersect = exitingCustomerNumbers.Intersect(customerNumbers).ToArray();
            if (intersect.Any())
            {
                ValidationResult = new ExecutionResult("duplicateCustomerNumber", string.Join(",", intersect));
                return false;
            }

            return true;
        }

        static IEnumerable<string> GetSplitCustomerNumbers(IEnumerable<string> customerNumberGroups)
        {
            return (from raw in customerNumberGroups
                    from customerNumber in raw.Split(',')
                    let cn = customerNumber.Trim()
                    where !string.IsNullOrWhiteSpace(cn)
                    select cn).Distinct().ToList();
        }

        static IEnumerable<string> DuplicateNumbers(string customerNumbers)
        {
            return customerNumbers.Split(',').Select(s => s.Trim()).GroupBy(s => s).Where(g => g.Count() > 1).Select(g => g.Key).ToList();
        }
    }
}
