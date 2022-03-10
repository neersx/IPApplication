using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Validators;
using InprotechKaizen.Model.Components.Security;
using Newtonsoft.Json;

namespace Inprotech.Integration.Uspto.PrivatePair.Sponsorships
{
    public interface ISponsorshipProcessor
    {
        Task<ExecutionResult> CreateSponsorship(SponsorshipModel model);
        Task<ExecutionResult> UpdateSponsorship(SponsorshipModel model);
        Task<ExecutionResult> UpdateOneTimeGlobalAccountSettings(string queueUrl, string queueId, string queueSecret);
        Task<IEnumerable<SponsorshipModel>> GetSponsorships();
        Task DeleteSponsorship(int id);
    }

    public class SponsorshipProcessor : ISponsorshipProcessor
    {
        readonly IPrivatePairService _privatePairService;
        readonly IRepository _repository;
        readonly ISecurityContext _securityContext;
        readonly Func<DateTime> _systemClock;

        public SponsorshipProcessor(ISecurityContext securityContext, IRepository repository,
                                    IPrivatePairService privatePairService, Func<DateTime> systemClock)
        {
            _securityContext = securityContext;
            _repository = repository;
            _privatePairService = privatePairService;
            _systemClock = systemClock;
        }

        public async Task<ExecutionResult> CreateSponsorship(SponsorshipModel model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));

            var validationResults = FieldValidationResults(model).ToArray();
            if (validationResults.Any())
            {
                throw new ArgumentException(string.Join(", ", validationResults));
            }

            if (!new DuplicateCustomerNumberValidator(_repository).Then(new DuplicateSponsorshipValidator(_repository))
                                                                  .IsValid(model, out var errors))
            {
                return errors;
            }

            var sponsorship = new Sponsorship
            {
                SponsorName = model.SponsorName,
                SponsoredAccount = model.SponsoredEmail,
                CustomerNumbers = model.CustomerNumbers,
                CreatedBy = _securityContext.User.Id,
                CreatedOn = _systemClock(),
                StatusDate = _systemClock(),
                IsDeleted = false
            };

            _repository.Set<Sponsorship>().Add(sponsorship);

            await _privatePairService.CheckOrCreateAccount();

            var serviceId = await _privatePairService.DispatchCrawlerService(model.SponsoredEmail, model.Password, model.AuthenticatorKey, model.SponsorName, GetCustomerArray(model.CustomerNumbers));

            if (string.IsNullOrWhiteSpace(serviceId))
            {
                throw new Exception("Service creation failed");
            }

            sponsorship.ServiceId = serviceId;

            await _repository.SaveChangesAsync();

            return new ExecutionResult();
        }

        public async Task<ExecutionResult> UpdateSponsorship(SponsorshipModel model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));

            var validationResults = FieldValidationResultsForUpdate(model).ToArray();
            if (validationResults.Any())
            {
                throw new ArgumentException(string.Join(", ", validationResults));
            }

            if (!new DuplicateCustomerNumberValidator(_repository).IsValid(model, out var customerNumberErrors))
            {
                return customerNumberErrors;
            }

            var existing = await _repository.Set<Sponsorship>().SingleAsync(s => s.Id == model.Id);
            var (hasCustomerNumberChanged, newCustomerNumbers) = HasCustomerNumberChanged(existing.CustomerNumbers, model.CustomerNumbers);

            if (!HasAnyServiceChange(model, hasCustomerNumberChanged))
            {
                return new ExecutionResult("noChange");
            }

            var result = await _privatePairService.UpdateServiceDetails(model.ServiceId, model.Password, model.AuthenticatorKey, hasCustomerNumberChanged ? newCustomerNumbers : null);
            if (!result.Updated)
            {
                return new ExecutionResult(result.Reason ?? "failedUpdate");
            }

            await UpdateExistingSponsorship(existing, model, hasCustomerNumberChanged);
            return new ExecutionResult();
        }

        public async Task<IEnumerable<SponsorshipModel>> GetSponsorships()
        {
            var sponsorships = _repository.NoDeleteSet<Sponsorship>()
                                          .OrderBy(c => c.SponsorName)
                                          .Select(s => new SponsorshipModel
                                          {
                                              Id = s.Id,
                                              SponsorName = s.SponsorName,
                                              SponsoredEmail = s.SponsoredAccount,
                                              CustomerNumbers = s.CustomerNumbers,
                                              ServiceId = s.ServiceId,
                                              Status = s.Status,
                                              ErrorMessage = s.StatusMessage,
                                              StatusDate = s.StatusDate
                                          }).ToArrayAsync();

            return await sponsorships;
        }

        public async Task<ExecutionResult> UpdateOneTimeGlobalAccountSettings(string queueUrl, string queueId, string queueSecret)
        {
            var lastSuccessfulRun = await GetLastSuccessfulScheduleDate();
            var result = await _privatePairService.UpdateOneTimeGlobalAccountSettings(lastSuccessfulRun, _systemClock(), queueId, queueSecret, queueUrl);
            if (!result.Updated)
            {
                return new ExecutionResult(result.Reason ?? "failedUpdate");
            }

            return new ExecutionResult();
        }

        public async Task DeleteSponsorship(int id)
        {
            var sponsorship = await _repository.NoDeleteSet<Sponsorship>()
                                               .SingleAsync(c => c.Id == id);

            sponsorship.IsDeleted = true;
            sponsorship.DeletedBy = _securityContext.User.Id;
            sponsorship.DeletedOn = _systemClock();

            if (!string.IsNullOrWhiteSpace(sponsorship.ServiceId))
            {
                await _privatePairService.DecommissionCrawlerService(sponsorship.ServiceId);
                sponsorship.ServiceId = null;
            }

            await _repository.SaveChangesAsync();

            if (!_repository.NoDeleteSet<Sponsorship>().Any())
            {
                await _privatePairService.DeleteAccount();
            }
        }

        static string[] GetCustomerArray(string customerNumbers)
        {
            return string.IsNullOrWhiteSpace(customerNumbers) ? null : customerNumbers.Split(',').Select(s => s.Trim()).Distinct().ToArray();
        }

        IEnumerable<string> FieldValidationResults(SponsorshipModel model)
        {
            if (model == null)
            {
                yield return nameof(SponsorshipModel);
                yield break;
            }

            if (string.IsNullOrWhiteSpace(model.SponsorName))
            {
                yield return nameof(model.SponsorName);
            }

            if (string.IsNullOrWhiteSpace(model.SponsoredEmail) || !new EmailFormatValidator().IsValid(model.SponsoredEmail))
            {
                yield return nameof(model.SponsoredEmail);
            }

            if (string.IsNullOrWhiteSpace(model.Password))
            {
                yield return nameof(model.Password);
            }

            if (string.IsNullOrWhiteSpace(model.AuthenticatorKey))
            {
                yield return nameof(model.AuthenticatorKey);
            }

            if (string.IsNullOrWhiteSpace(model.CustomerNumbers) || !new CustomerNumberFormatValidator().IsValid(model.CustomerNumbers))
            {
                yield return nameof(model.CustomerNumbers);
            }
        }

        IEnumerable<string> FieldValidationResultsForUpdate(SponsorshipModel model)
        {
            if (model == null)
            {
                yield return nameof(SponsorshipModel);
                yield break;
            }

            if (string.IsNullOrWhiteSpace(model.SponsorName))
            {
                yield return nameof(model.SponsorName);
            }

            if (string.IsNullOrWhiteSpace(model.SponsoredEmail) || !new EmailFormatValidator().IsValid(model.SponsoredEmail))
            {
                yield return nameof(model.SponsoredEmail);
            }

            if (string.IsNullOrWhiteSpace(model.ServiceId))
            {
                yield return nameof(model.ServiceId);
            }

            if (string.IsNullOrWhiteSpace(model.CustomerNumbers) || !new CustomerNumberFormatValidator().IsValid(model.CustomerNumbers))
            {
                yield return nameof(model.CustomerNumbers);
            }
        }

        (bool hasCustomerNumberChanged, string[] newCustomerNumbers) HasCustomerNumberChanged(string existing, string @new)
        {
            var existingCustomerNumbers = GetCustomerArray(existing);
            var newCustomerNumbers = GetCustomerArray(@new);
            var customerUnChanged = existingCustomerNumbers.Length == newCustomerNumbers.Length
                                    && existingCustomerNumbers.Intersect(newCustomerNumbers).ToArray().Length == existingCustomerNumbers.Length;
            return (!customerUnChanged, newCustomerNumbers);
        }

        bool HasAnyServiceChange(SponsorshipModel model, bool hasCustomerNumberChanged)
        {
            return hasCustomerNumberChanged || !model.Password.IsNullOrEmpty() || !model.AuthenticatorKey.IsNullOrEmpty();
        }

        async Task UpdateExistingSponsorship(Sponsorship sponsorship, SponsorshipModel model, bool hasCustomerNumberChanged)
        {
            if (hasCustomerNumberChanged)
            {
                sponsorship.CustomerNumbers = model.CustomerNumbers;
            }

            sponsorship.Status = SponsorshipStatus.Submitted;
            sponsorship.StatusDate = _systemClock();
            sponsorship.StatusMessage = null;

            await _repository.SaveChangesAsync();
        }

        async Task<DateTime> GetLastSuccessfulScheduleDate()
        {
            const int maxTotalDaysToSchedule = 14;
            DateTime lastSuccessfulRun = _systemClock().AddDays(-1);
            var sc = await _repository.Set<ScheduleExecution>()
                                .Include(_ => _.Schedule)
                                .Where(_ => _.Schedule.DataSourceType == DataSourceType.UsptoPrivatePair && !_.Schedule.IsDeleted && _.Status == ScheduleExecutionStatus.Complete)
                                .OrderByDescending(_ => _.Id)
                                .FirstOrDefaultAsync();
            if (sc != null)
            {
                var daysDifference = (_systemClock() - sc.Started).TotalDays;
                lastSuccessfulRun = daysDifference > maxTotalDaysToSchedule ? _systemClock().AddDays(-maxTotalDaysToSchedule) : _systemClock().AddDays(-daysDifference);
            }

            return lastSuccessfulRun;
        }
    }

    public class SponsorshipModel
    {
        [JsonProperty("Id")]
        public int Id { get; set; }

        [JsonProperty("name")]
        public string SponsorName { get; set; }

        [JsonProperty("email")]
        [DataType(DataType.EmailAddress)]
        public string SponsoredEmail { get; set; }

        [JsonProperty("password")]
        public string Password { get; set; }

        [JsonProperty("authenticatorKey")]
        public string AuthenticatorKey { get; set; }

        [JsonProperty("customerNumbers")]
        public string CustomerNumbers { get; set; }

        [JsonProperty("serviceId")]
        public string ServiceId { get; set; }

        public SponsorshipStatus Status { get; set; }

        public string ErrorMessage { get; set; }
        public DateTime StatusDate { get; set; }
    }
}