using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes;
using InprotechKaizen.Model.Components.Integration.Exchange;
using Microsoft.Exchange.WebServices.Data;
using Newtonsoft.Json;
using AwaitableTask = System.Threading.Tasks.Task;
using Task = Microsoft.Exchange.WebServices.Data.Task;

namespace Inprotech.IntegrationServer.ExchangeIntegration.Strategy.Ews
{
    public class ExchangeWebService : IExchangeService
    {
        readonly ExtendedPropertyDefinition _dateCreatedProperty = new ExtendedPropertyDefinition(DefaultExtendedPropertySet.PublicStrings, KnownValues.NamespaceReminder + "dateCreated", MapiPropertyType.String);
        readonly IBackgroundProcessLogger<IExchangeService> _logger;
        readonly IExchangeServiceConnection _serviceConnection;
        readonly ExtendedPropertyDefinition _staffKeyProperty = new ExtendedPropertyDefinition(DefaultExtendedPropertySet.PublicStrings, KnownValues.NamespaceReminder + "staffKey", MapiPropertyType.Integer);

        public ExchangeWebService(IExchangeServiceConnection serviceConnection, IBackgroundProcessLogger<IExchangeService> logger)
        {
            _serviceConnection = serviceConnection;
            _logger = logger;
        }

        public AwaitableTask CreateOrUpdateAppointment(ExchangeConfigurationSettings exchangeSettings, ExchangeItemRequest request, int userId)
        {
            if (exchangeSettings == null) throw new ArgumentNullException(nameof(exchangeSettings));

            CreateOrUpdateAppointment(exchangeSettings, request, true);

            return AwaitableTask.FromResult((object)null);
        }

        public AwaitableTask CreateOrUpdateTask(ExchangeConfigurationSettings exchangeSettings, ExchangeItemRequest request, int userId)
        {
            if (exchangeSettings == null) throw new ArgumentNullException(nameof(exchangeSettings));

            CreateOrUpdateTask(exchangeSettings, request, true);

            return AwaitableTask.FromResult((object)null);
        }

        public AwaitableTask UpdateAppointment(ExchangeConfigurationSettings exchangeSettings, ExchangeItemRequest request, int userId)
        {
            if (exchangeSettings == null) throw new ArgumentNullException(nameof(exchangeSettings));

            CreateOrUpdateAppointment(exchangeSettings, request, false);

            return AwaitableTask.FromResult((object)null);
        }

        public AwaitableTask UpdateTask(ExchangeConfigurationSettings exchangeSettings, ExchangeItemRequest request, int userId)
        {
            if (exchangeSettings == null) throw new ArgumentNullException(nameof(exchangeSettings));

            CreateOrUpdateTask(exchangeSettings, request, false);

            return AwaitableTask.FromResult((object)null);
        }

        public AwaitableTask DeleteAppointment(ExchangeConfigurationSettings settings, int staffId, DateTime dateKey, string mailbox, int userId)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));

            var service = _serviceConnection.Get(settings, mailbox);
            var findItemResponse = FindFrom(service, WellKnownFolderName.Calendar, staffId, dateKey);

            if (findItemResponse.Any())
            {
                var items = findItemResponse.Items.Where(i => i is Appointment).ToArray();
                foreach (var item in items)
                    item.Delete(DeleteMode.MoveToDeletedItems);
                
                _logger.Trace($"#{items.Length} appointments deleted");

            }

            return AwaitableTask.FromResult((object)null);
        }

        public AwaitableTask DeleteTask(ExchangeConfigurationSettings settings, int staffId, DateTime dateKey, string mailbox, int userId)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));
            var service = _serviceConnection.Get(settings, mailbox);

            var findItemResponse = FindFrom(service, WellKnownFolderName.Tasks, staffId, dateKey);

            if (findItemResponse.Any())
            {
                var items = findItemResponse.Items.Where(i => i is Task).ToArray();
                foreach (var item in items)
                    item.Delete(DeleteMode.MoveToDeletedItems);

                _logger.Trace($"#{items.Length} tasks deleted");
            }

            return AwaitableTask.FromResult((object)null);
        }

        public Task<bool> CheckStatus(ExchangeConfigurationSettings settings, string mailbox, int userId)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));
            try
            {
                _logger.Information("Checking access to mailbox: " + mailbox);
                var service = _serviceConnection.Get(settings, mailbox);
                var response = service.FindFolders(WellKnownFolderName.Calendar, new FolderView(10));
                return AwaitableTask.FromResult(response != null);
            }
            catch (Exception ex)
            {
                _logger.Exception(ex);
                return AwaitableTask.FromResult(false);
            }
        }

        public AwaitableTask SaveDraftEmail(ExchangeConfigurationSettings settings, ExchangeItemRequest request, int userId)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));

            var service = _serviceConnection.Get(settings, request.Mailbox);

            var message = new EmailMessage(service);

            foreach (var to in Split(request.RecipientEmail))
                message.ToRecipients.Add(new EmailAddress(to));

            foreach (var cc in Split(request.CcRecipientEmails))
                message.CcRecipients.Add(new EmailAddress(cc));

            foreach (var bcc in Split(request.BccRecipientEmails))
                message.BccRecipients.Add(new EmailAddress(bcc));

            message.Subject = request.Subject;

            message.Body = request.IsBodyHtml
                ? new MessageBody(BodyType.HTML, request.Body)
                : new MessageBody(request.Body);

            foreach (var at in Deserialize(request.Attachments))
            {
                if (at.IsInline && !string.IsNullOrWhiteSpace(at.Content))
                {
                    var fileAttachment = message.Attachments.AddFileAttachment(at.ContentId, at.GetContentStream());
                    fileAttachment.ContentId = at.ContentId;
                    fileAttachment.IsInline = true;
                    continue;
                }

                if (!string.IsNullOrEmpty(at.FileName) && !string.IsNullOrEmpty(at.Content))
                {
                    message.Attachments.AddFileAttachment(at.FileName, at.GetContentStream());
                    continue;
                }

                if (!string.IsNullOrWhiteSpace(at.FileName))
                {
                    message.Attachments.AddFileAttachment(at.FileName);
                }
            }

            message.Save(WellKnownFolderName.Drafts);

            _logger.Trace($"Draft email persisted in {request.Mailbox}");

            return AwaitableTask.FromResult((object)null);
        }

        static IEnumerable<string> Split(string input)
        {
            return input?.Split(new[] { ';' }, StringSplitOptions.RemoveEmptyEntries) ?? Enumerable.Empty<string>();
        }

        static IEnumerable<EmailAttachment> Deserialize(string input)
        {
            if (string.IsNullOrWhiteSpace(input))
                return Enumerable.Empty<EmailAttachment>();

            return JsonConvert.DeserializeObject<IEnumerable<EmailAttachment>>(input);
        }

        void CreateOrUpdateAppointment(ExchangeConfigurationSettings settings, ExchangeItemRequest request, bool createIfNotFound)
        {
            var service = _serviceConnection.Get(settings, request.RecipientEmail);
            var findItemResponse = FindFrom(service, WellKnownFolderName.Calendar, request.StaffId, request.CreatedOn);
            if (findItemResponse.Any())
            {
                UpdateAppointments(request, findItemResponse);
            }

            if (createIfNotFound)
            {
                CreateAppointment(request, service);
            }
        }

        void UpdateAppointments(ExchangeItemRequest request, FindItemsResults<Item> findItemResponse)
        {
            var appointments = findItemResponse.Items.Where(i => i is Appointment).ToArray();
            foreach (var item in appointments)
            {
                var appointment = (Appointment)item;

                appointment.Subject = request.Subject;
                appointment.Body = new MessageBody(request.Body);
                appointment.Start = request.DueDate ?? DateTime.MinValue;
                appointment.End = request.DueDate ?? DateTime.MinValue;
                appointment.Importance = request.IsHighPriority ? Importance.High : Importance.Normal;
                appointment.SetExtendedProperty(_staffKeyProperty, request.StaffId);
                appointment.SetExtendedProperty(_dateCreatedProperty, request.CreatedOn.ToString(KnownValues.DateFormatReminder));

                if (request.ReminderDate.HasValue)
                {
                    appointment.ReminderDueBy = request.ReminderDate.Value;
                    appointment.IsReminderSet = request.IsReminderRequired;
                }

                appointment.Update(ConflictResolutionMode.AlwaysOverwrite, SendInvitationsOrCancellationsMode.SendToChangedAndSaveCopy);
            }

            _logger.Trace($"#{appointments.Length} appointments updated [staffId={request.StaffId}/dateCreated={request.CreatedOn}]");
        }

        void CreateAppointment(ExchangeItemRequest request, ExchangeService service)
        {
            var appointment = new Appointment(service)
            {
                Subject = request.Subject,
                Body = new MessageBody(request.Body),
                Start = request.DueDate ?? DateTime.MinValue,
                End = request.DueDate ?? DateTime.MinValue,
                Importance = request.IsHighPriority ? Importance.High : Importance.Normal
            };

            appointment.SetExtendedProperty(_staffKeyProperty, request.StaffId);
            appointment.SetExtendedProperty(_dateCreatedProperty, request.CreatedOn.ToString(KnownValues.DateFormatReminder));

            if (request.ReminderDate.HasValue)
            {
                appointment.ReminderDueBy = request.ReminderDate.Value;
                appointment.IsReminderSet = request.IsReminderRequired;
            }

            appointment.Save(new FolderId(WellKnownFolderName.Calendar, request.RecipientEmail));

            _logger.Trace($"appointment created [staffId={request.StaffId}/dateCreated={request.CreatedOn}]");
        }

        void CreateOrUpdateTask(ExchangeConfigurationSettings settings, ExchangeItemRequest request, bool createIfNotFound)
        {
            var service = _serviceConnection.Get(settings, request.RecipientEmail);
            var findItemResponse = FindFrom(service, WellKnownFolderName.Tasks, request.StaffId, request.CreatedOn);
            if (findItemResponse.Any())
            {
                UpdateTasks(request, findItemResponse);
                return;
            }

            if (createIfNotFound)
            {
                CreateTask(request, service);
            }
        }

        void UpdateTasks(ExchangeItemRequest request, FindItemsResults<Item> findItemResponse)
        {
            var tasks = findItemResponse.Items.Where(i => i is Task).ToArray();
            foreach (var item in tasks)
            {
                var task = (Task)item;
                task.Subject = request.Subject;
                task.Body = new MessageBody(request.Body);
                task.DueDate = request.DueDate ?? DateTime.MinValue;
                task.Importance = request.IsHighPriority ? Importance.High : Importance.Normal;
                task.SetExtendedProperty(_staffKeyProperty, request.StaffId);
                task.SetExtendedProperty(_dateCreatedProperty, request.CreatedOn.ToString(KnownValues.DateFormatReminder));

                if (request.ReminderDate.HasValue)
                {
                    task.ReminderDueBy = request.ReminderDate.Value;
                    task.IsReminderSet = request.IsReminderRequired;
                }

                task.Update(ConflictResolutionMode.AlwaysOverwrite);
            }
            
            _logger.Trace($"#{tasks.Length} tasks updated [staffId={request.StaffId}/dateCreated={request.CreatedOn}]");
        }

        void CreateTask(ExchangeItemRequest request, ExchangeService service)
        {
            var task = new Task(service)
            {
                Subject = request.Subject,
                Body = new MessageBody(request.Body),
                DueDate = request.DueDate ?? DateTime.MinValue,
                Importance = request.IsHighPriority ? Importance.High : Importance.Normal
            };

            task.SetExtendedProperty(_staffKeyProperty, request.StaffId);
            task.SetExtendedProperty(_dateCreatedProperty, request.CreatedOn.ToString(KnownValues.DateFormatReminder));

            if (request.ReminderDate.HasValue)
            {
                task.ReminderDueBy = request.ReminderDate.Value;
                task.IsReminderSet = request.IsReminderRequired;
            }

            task.Save(new FolderId(WellKnownFolderName.Tasks, request.RecipientEmail));

            _logger.Trace($"task created [staffId={request.StaffId}/dateCreated={request.CreatedOn}]");
        }

        FindItemsResults<Item> FindFrom(ExchangeService service, FolderId folder, int staffKey, DateTime dateCreated)
        {
            var coll = new SearchFilter.SearchFilterCollection(LogicalOperator.And);
            var staffKeyEquals = new SearchFilter.IsEqualTo(_staffKeyProperty, staffKey);
            var dateCreatedEquals = new SearchFilter.IsEqualTo(_dateCreatedProperty, dateCreated.ToString(KnownValues.DateFormatReminder));
            coll.Add(staffKeyEquals);
            coll.Add(dateCreatedEquals);

            var view = new ItemView(10);
            return service.FindItems(folder, coll, view);
        }

        public void SetLogContext(Guid context)
        {
            _logger.SetContext(context);
        }
    }
    
}