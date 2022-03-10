using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.DataValidation;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks
{
    public interface IDataEntryTaskDispatcher
    {
        DataEntryTaskCompletionResult Validate(DataEntryTaskInput data);
        DataEntryTaskCompletionResult ApplyChanges(DataEntryTaskInput data);
    }

    public class DataEntryTaskDispatcher : IDataEntryTaskDispatcher
    {
        readonly IExternalDataValidator _dataValidator;
        readonly IDbContext _dbContext;
        readonly IEnumerable<IDataEntryTaskHandler> _handlers;
        readonly ISecurityContext _securityContext;
        readonly Func<DateTime> _systemClock;
        readonly ITransactionRecordal _transactionRecordal;
        readonly IComponentResolver _componentResolver;

        public DataEntryTaskDispatcher(
            IDbContext dbContext,
            IEnumerable<IDataEntryTaskHandler> handlers,
            IPolicingEngine policingEngine,
            ISecurityContext securityContext,
            Func<DateTime> systemClock,
            IExternalDataValidator dataValidator,
            ITransactionRecordal transactionRecordal,
            IComponentResolver componentResolver)
        {
            if(dbContext == null) throw new ArgumentNullException("dbContext");
            if(handlers == null) throw new ArgumentNullException("handlers");
            if(policingEngine == null) throw new ArgumentNullException("policingEngine");
            if(securityContext == null) throw new ArgumentNullException("securityContext");
            if(systemClock == null) throw new ArgumentNullException("systemClock");
            if(dataValidator == null) throw new ArgumentNullException("dataValidator");
            if(transactionRecordal == null) throw new ArgumentNullException("transactionRecordal");

            _dbContext = dbContext;
            _handlers = handlers;
            _securityContext = securityContext;
            _systemClock = systemClock;
            _dataValidator = dataValidator;
            _transactionRecordal = transactionRecordal;
            _componentResolver = componentResolver;
        }

        public DataEntryTaskCompletionResult Validate(DataEntryTaskInput data)
        {
            if(data == null) throw new ArgumentNullException("data");
            return InvokeHandlers(data, h => h.ValidateThunk);
        }

        public DataEntryTaskCompletionResult ApplyChanges(DataEntryTaskInput data)
        {
            if(data == null) throw new ArgumentNullException("data");
            return InvokeHandlers(data, h => h.ApplyChangesThunk);
        }

        DataEntryTaskCompletionResult InvokeHandlers(
            DataEntryTaskInput dataInput,
            Func
                <DataEntryTaskHandlerInfo,
                Func
                <object, Case, DataEntryTask, object,
                DataEntryTaskHandlerOutput>> target)
        {
            var transactionNo = _transactionRecordal.RecordTransactionFor(
                                                                          dataInput.Case,
                                                                          CaseTransactionMessageIdentifier.AmendedCase,
                                                                          componentId: _componentResolver.Resolve(KnownComponents.BatchEventUpdate));

            var handlerResults = new List<DataEntryTaskHandlerResult>(_handlers.Count());

            if(!VerifyStatusChangePassword(dataInput))
            {
                return new DataEntryTaskCompletionResult(
                    new ValidationResult(
                        "Your changes have not been saved because you have entered an incorrect password.")
                        .Named("InvalidPasswordForStatusChange"));
            }

            var hasErrors = false;
            var hasWarnings = false;

            var handlersMap = _handlers.ToDictionary(h => h.Name, h => h);

            foreach(var d in dataInput.Data)
            {
                IDataEntryTaskHandler handler;
                if(!handlersMap.TryGetValue(d.Key, out handler))
                    continue;

                var handlerInfo = DataEntryTaskHandlerInfoCache.Resolve(handler);
                var output = target(handlerInfo)(handler, dataInput.Case, dataInput.DataEntryTask, d.Value);
                hasErrors |= output.HasErrors;
                hasWarnings |= output.HasWarnings;
                handlerResults.Add(new DataEntryTaskHandlerResult(handler.Name, output));
            }

            if(hasErrors || (hasWarnings && !dataInput.BypassWarnings))
                return new DataEntryTaskCompletionResult(false, handlerResults.ToArray());

            ApplyStatuses(dataInput.Case, dataInput.DataEntryTask);
            _dbContext.SaveChanges();

            var evr = ExternalDataValidationResults(dataInput, transactionNo);

            return new DataEntryTaskCompletionResult(
                evr.All(r => r.Severity == Severity.Information),
                handlerResults.ToArray(),
                evr);
        }

        ValidationResult[] ExternalDataValidationResults(DataEntryTaskInput dataInput, int transactionNo)
        {
            var evr = _dataValidator.Validate(dataInput.Case.Id, null, transactionNo).ToArray();

            return
                evr.All(
                        r =>
                        dataInput.SanityCheckResultIds.Any(pr => pr == r.Details.CorrelationId))
                    ? new ValidationResult[0]
                    : evr;
        }

        bool VerifyStatusChangePassword(DataEntryTaskInput input)
        {
            if(!input.DataEntryTask.ShouldConfirmStatusChangeOnSave(input.Case))
                return true;

            var confirmationPassword = _dbContext.Set<SiteControl>()
                                                 .FirstOrDefault(
                                                                 sc => sc.ControlId == SiteControls.ConfirmationPasswd
                                                                       && !string.IsNullOrEmpty(sc.StringValue));

            if(confirmationPassword == null)
                return true;

            return confirmationPassword.StringValue == input.ConfirmationPassword;
        }

        void ApplyStatuses(Case @case, DataEntryTask dataEntryTask)
        {
            if(dataEntryTask.CaseStatus != null && @case.CaseStatus != dataEntryTask.CaseStatus)
            {
                @case.RecordCaseStatusChangeActivity(dataEntryTask, _securityContext.User, _systemClock());
                @case.CaseStatus = dataEntryTask.CaseStatus;
            }

            if(dataEntryTask.RenewalStatus == null) return;
            var property = _dbContext.Set<CaseProperty>().SingleOrDefault(c => c.CaseId == @case.Id);
            if(property != null)
                property.SetRenewalStatus(dataEntryTask.RenewalStatus);
        }
    }
}