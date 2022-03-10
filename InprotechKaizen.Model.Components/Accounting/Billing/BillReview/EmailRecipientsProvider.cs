using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.BillReview
{
    public interface IEmailRecipientsProvider
    {
        Task<Dictionary<int, IEnumerable<string>>> Provide(int debtorId, IEnumerable<DebtorCopiesTo> debtorCopies);
    }

    public class EmailRecipientsProvider : IEmailRecipientsProvider
    {
        readonly ILogger<EmailRecipientsProvider> _logger;
        readonly IDbContext _dbContext;
        readonly IEmailValidator _emailValidator;
        readonly Dictionary<int, HashSet<string>> _emailAddresses = new();
        
        public EmailRecipientsProvider(ILogger<EmailRecipientsProvider> logger,
                                                 IDbContext dbContext,
                                                 IEmailValidator emailValidator)
        {
            _logger = logger;
            _dbContext = dbContext;
            _emailValidator = emailValidator;
        }

        public async Task<Dictionary<int, IEnumerable<string>>> Provide(int debtorId, IEnumerable<DebtorCopiesTo> debtorCopies)
        {
            if (debtorCopies == null) throw new ArgumentNullException(nameof(debtorCopies));

            var nameIds = GetNameIds(debtorId, debtorCopies);

            await PopulateEmailAddressesForNameIds(nameIds);
            
            return EmailAddressesOfRequestedNameIds(nameIds);
        }

        Dictionary<int, IEnumerable<string>> EmailAddressesOfRequestedNameIds(int[] nameIds)
        {
            var result = new Dictionary<int, IEnumerable<string>>();

            foreach (var nameId in nameIds)
            {
                var emails = _emailAddresses.Get(nameId) ?? Enumerable.Empty<string>();
                result.Add(nameId, emails);
            }

            return result;
        }

        async Task PopulateEmailAddressesForNameIds(int[] nameIds)
        {
            var nameIdsToQuery = nameIds.Where(_ => !_emailAddresses.Keys.Contains(_)).ToArray();

            if (!nameIdsToQuery.Any())
                return;

            var mainEmails = await (from t in _dbContext.Set<Telecommunication>()
                                    join n in _dbContext.Set<Name>() on t.Id equals n.MainEmailId
                                    where nameIdsToQuery.Contains(n.Id)
                                    select new
                                    {
                                        n.Id,
                                        Email = t.TelecomNumber
                                    }).ToArrayAsync();
            
            var nonMainEmails = await (from n in _dbContext.Set<Name>()
                                 join nt in _dbContext.Set<NameTelecom>() on n.Id equals nt.NameId
                                 join t in _dbContext.Set<Telecommunication>() on nt.TeleCode equals t.Id into t1
                                 from t in t1
                                 where nameIdsToQuery.Contains(n.Id)
                                       && t.TelecomType.Id == (short)KnownTelecomTypes.Email
                                       && n.MainEmailId == null
                                 select new
                                 {
                                     n.Id,
                                     Email = t.TelecomNumber
                                 }).ToArrayAsync();

            var allEmailsByNameIds = (from n in mainEmails.Union(nonMainEmails)
                                      let sanitised = n.Email?.Trim()
                                      where !string.IsNullOrWhiteSpace(sanitised)
                                      group n by n.Id
                                      into g1
                                      select new
                                      {
                                          NameId = g1.Key,
                                          Emails = g1.Select(_ => _.Email)
                                      }).ToDictionary(k => k.NameId, v => v.Emails.ToArray());

            foreach (var emailByNameId in allEmailsByNameIds)
            {
                var nameId = emailByNameId.Key;
                var r = new HashSet<string>();

                foreach (var email in allEmailsByNameIds[nameId])
                {
                    if (!_emailValidator.IsValid(email))
                    {
                        _logger.Warning($"{nameof(BillReviewEmailBuilder)}: Debtor email {emailByNameId} is invalid, excluded from recipient list.");
                        continue;
                    }

                    r.Add(email);
                }

                _emailAddresses.Add(nameId, r);
            }
        }

        static int[] GetNameIds(int debtorId, IEnumerable<DebtorCopiesTo> debtorCopiesTos)
        {
            var nameIds = new HashSet<int>(new[] { debtorId });

            foreach (var debtorCopiesTo in debtorCopiesTos)
            {
                if (debtorCopiesTo.ContactNameId != null)
                {
                    nameIds.Add((int) debtorCopiesTo.ContactNameId);
                }

                nameIds.Add(debtorCopiesTo.CopyToNameId);
            }

            return nameIds.ToArray();
        }
    }
}
