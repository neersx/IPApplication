using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Integration.ExchangeIntegration;
using Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes;
using Inprotech.IntegrationServer.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Integration.Exchange;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;

namespace Inprotech.IntegrationServer.ExchangeIntegration.Strategy.Graph
{

    public class GraphClient : IExchangeService
    {
        readonly string _baseEmailUrl = "/v1.0/me/messages";
        readonly string _baseEventUrl = "/v1.0/me/events";
        readonly string _baseTaskUrl = "/v1.0/me/todo/lists/{0}/tasks";
        readonly string _extendedPropertyDateCreated = "String {" + KnownValues.PublicStringGuid + "} Name " + KnownValues.NamespaceReminder + "dateCreated";
        readonly string _extendedPropertyStaffKey = "Integer {" + KnownValues.PublicStringGuid + "} Name " + KnownValues.NamespaceReminder + "staffKey";
        readonly IFileSystem _fileSystem;
        readonly IGraphAccessTokenManager _graphAccessTokenManager;
        readonly IGraphHttpClient _graphHttpClient;
        readonly IGraphNotification _graphNotification;
        readonly IGraphResourceManager _graphResourceManager;
        readonly IGraphTaskIdCache _graphTaskIdCache;
        readonly IBackgroundProcessLogger<IExchangeService> _logger;

        public GraphClient(
            IBackgroundProcessLogger<IExchangeService> logger,
            IGraphHttpClient graphHttpClient,
            IGraphNotification graphNotification,
            IGraphAccessTokenManager graphAccessTokenManager,
            IGraphResourceManager graphResourceManager,
            IGraphTaskIdCache graphTaskIdCache,
            IFileSystem fileSystem
        )
        {
            _logger = logger;
            _graphHttpClient = graphHttpClient;
            _graphNotification = graphNotification;
            _graphAccessTokenManager = graphAccessTokenManager;
            _graphResourceManager = graphResourceManager;
            _graphTaskIdCache = graphTaskIdCache;
            _fileSystem = fileSystem;
            JsonConvert.DefaultSettings = () => new JsonSerializerSettings
            {
                ContractResolver = new CamelCasePropertyNamesContractResolver()
            };
        }

        public async Task CreateOrUpdateAppointment(ExchangeConfigurationSettings settings, ExchangeItemRequest request, int userId)
        {
            await RefreshTokenOnExpire(async force => { await CreateOrUpdateAppointment(settings, request, true, userId); }, settings, userId);
        }

        public async Task UpdateAppointment(ExchangeConfigurationSettings settings, ExchangeItemRequest request, int userId)
        {
            await RefreshTokenOnExpire(async force => { await CreateOrUpdateAppointment(settings, request, false, userId); }, settings, userId);
        }

        public async Task DeleteAppointment(ExchangeConfigurationSettings settings, int staffId, DateTime dateKey, string mailbox, int userId)
        {
            await RefreshTokenOnExpire(async force =>
            {
                var appointments = await GetAppointmentsAsync(_baseEventUrl, userId, staffId, dateKey);
                if (appointments.Any())
                {
                    foreach (var appointment in appointments)
                    {
                        await _graphHttpClient.Delete(userId, $"{_baseEventUrl}/{appointment.Id}");
                    }
                }
            }, settings, userId);
        }

        public async Task CreateOrUpdateTask(ExchangeConfigurationSettings settings, ExchangeItemRequest request, int userId)
        {
            await RefreshTokenOnExpire(async force => { await CreateOrUpdateTask(settings, request, true, userId); }, settings, userId);
        }

        public async Task UpdateTask(ExchangeConfigurationSettings settings, ExchangeItemRequest request, int userId)
        {
            await RefreshTokenOnExpire(async force => { await CreateOrUpdateTask(settings, request, false, userId); }, settings, userId);
        }

        public async Task DeleteTask(ExchangeConfigurationSettings settings, int staffId, DateTime dateKey, string mailbox, int userId)
        {
            await RefreshTokenOnExpire(async force =>
            {
                var baseUrl = await GetActualBaseTaskUrl(userId);
                var task = await GetTaskAsync(baseUrl, userId, staffId, dateKey);

                if (task == null) return;
                await _graphHttpClient.Delete(userId, $"{_baseTaskUrl}/{task.Id}");
                await _graphResourceManager.DeleteAsync(staffId, dateKey, KnownExchangeResourceType.Tasks, task.Id);
            }, settings, userId);
        }

        public async Task<bool> CheckStatus(ExchangeConfigurationSettings settings, string mailbox, int userId)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));

            return await RefreshTokenOnExpire(async force =>
            {
                _logger.Information("Testing connection ");

                var httpClient = await _graphHttpClient.GetClient(userId);
                var calendarsTask = httpClient.GetAsync("v1.0/me/calendars");
                var listsTask = httpClient.GetAsync("v1.0/me/todo/lists");
                var messagesTask = httpClient.GetAsync("v1.0/me/messages");

                var tasks = new List<Task<HttpResponseMessage>>();

                if (settings.IsReminderEnabled)
                {
                    tasks.Add(calendarsTask);
                    tasks.Add(listsTask);
                }

                if (settings.IsBillFinalisationEnabled || settings.IsDraftEmailEnabled)
                {
                    tasks.Add(messagesTask);
                }

                var response = await Task.WhenAny(tasks);

                if (response.Result.StatusCode == HttpStatusCode.Unauthorized)
                {
                    throw new GraphAccessTokenExpiredException(HttpStatusCode.Unauthorized.ToString());
                }

                return response.Result.IsSuccessStatusCode;
            }, settings, userId);
        }

        public async Task SaveDraftEmail(ExchangeConfigurationSettings settings, ExchangeItemRequest request, int userId)
        {
            await RefreshTokenOnExpire(async force =>
            {
                var message = new GraphEmailMessage
                {
                    To = new List<GraphEmailAddress>(),
                    Bcc = new List<GraphEmailAddress>(),
                    Cc = new List<GraphEmailAddress>()
                };
                foreach (var to in Split(request.RecipientEmail))
                    message.To.Add(new GraphEmailAddress { EmailAddress = new EmailAddress { Address = to } });

                foreach (var cc in Split(request.CcRecipientEmails))
                    message.Cc.Add(new GraphEmailAddress { EmailAddress = new EmailAddress { Address = cc } });

                foreach (var bcc in Split(request.BccRecipientEmails))
                    message.Bcc.Add(new GraphEmailAddress { EmailAddress = new EmailAddress { Address = bcc } });

                message.Subject = request.Subject;

                message.Body = new GraphMessageBody
                {
                    ContentType = request.IsBodyHtml ? GraphMessageBodyType.Html.ToString() : GraphMessageBodyType.Text.ToString(),
                    Content = request.Body
                };

                var attachmentNo = 0;
                foreach (var at in Deserialize(request.Attachments))
                {
                    message.Attachments = message.Attachments ?? new List<GraphAttachment>();
                    if (at.IsInline && !string.IsNullOrWhiteSpace(at.Content))
                    {
                        attachmentNo += 1;
                        message.Attachments.Add(new GraphAttachment
                        {
                            ContentId = at.ContentId,
                            IsInline = at.IsInline,
                            ContentBytes = at.GetContentStream().ToByteArray(),
                            Name = $"file{attachmentNo}"
                        });
                    }
                    else if (!string.IsNullOrEmpty(at.FileName) && !string.IsNullOrEmpty(at.Content))
                    {
                        message.Attachments.Add(new GraphAttachment
                        {
                            Name = _fileSystem.GetFileName(at.FileName),
                            ContentBytes = at.GetContentStream().ToByteArray()
                        });
                    }
                    else if (!string.IsNullOrWhiteSpace(at.FileName))
                    {
                        message.Attachments.Add(new GraphAttachment
                        {
                            Name = _fileSystem.GetFileName(at.FileName),
                            ContentBytes = _fileSystem.ReadAllBytes(at.FileName)
                        });
                    }
                }

                await _graphHttpClient.Post(userId, _baseEmailUrl, message);
                
                _logger.Trace($"Draft email persisted in {request.Mailbox}");

            }, settings, userId);
        }

        public void SetLogContext(Guid context)
        {
            _logger.SetContext(context);
        }

        async Task CreateOrUpdateAppointment(ExchangeConfigurationSettings settings, ExchangeItemRequest request, bool createIfNotFound, int userId)
        {
            var appointments = await GetAppointmentsAsync(_baseEventUrl, userId, request.StaffId, request.CreatedOn);
            if (appointments.Any())
            {
                foreach (var appointment in appointments)
                {
                    await _graphHttpClient.Patch(userId, $"{_baseEventUrl}/{appointment.Id}", GetAppointment(request, appointment));
                }

                _logger.Trace($"#{appointments.Count} appointments updated [staffId={request.StaffId}/dateCreated={request.CreatedOn}]");
                return;
            }

            if (createIfNotFound)
            {
                await _graphHttpClient.Post(userId, _baseEventUrl, GetAppointment(request, null));

                _logger.Trace($"appointment created [staffId={request.StaffId}/dateCreated={request.CreatedOn}]");
            }
        }

        async Task<List<GraphAppointment>> GetAppointmentsAsync(string baseUrl, int userId, int staffId, DateTime createdOn)
        {
            var res = await _graphHttpClient.Get(userId, PrepareSearchUrlAsync(baseUrl, staffId, createdOn));
            if (res.StatusCode == HttpStatusCode.Unauthorized)
            {
                throw new GraphAccessTokenExpiredException(HttpStatusCode.Unauthorized.ToString());
            }

            res.EnsureSuccessStatusCode();
            var graphAppointments = await res.Content.ReadAsAsync<GraphAppointments>();

            return graphAppointments.Value;
        }

        GraphAppointment GetAppointment(ExchangeItemRequest request, GraphAppointment e)
        {
            if (e == null)
            {
                e = new GraphAppointment();
            }

            var extendedProperties = new List<SingleValueExtendedProperty>();
            e.Subject = request.Subject;

            e.Body = new GraphMessageBody
            {
                ContentType = request.IsBodyHtml ? GraphMessageBodyType.Html.ToString() : GraphMessageBodyType.Text.ToString(),
                Content = request.Body
            };
            e.Start = new EventDate { DateTime = request.DueDate ?? DateTime.MinValue };
            e.End = new EventDate { DateTime = request.DueDate ?? DateTime.MinValue };
            e.Importance = request.IsHighPriority ? GraphImportance.High.ToString() : GraphImportance.Normal.ToString();

            if (request.ReminderDate.HasValue)
            {
                var ts = e.Start.DateTime - request.ReminderDate.Value;
                e.ReminderMinutesBeforeStart = (int)ts.TotalMinutes;
                e.IsReminderOn = request.IsReminderRequired;
            }

            extendedProperties.Add(new SingleValueExtendedProperty
            {
                Id = _extendedPropertyDateCreated,
                Value = request.CreatedOn.ToString(KnownValues.DateFormatReminder)
            });
            extendedProperties.Add(new SingleValueExtendedProperty
            {
                Id = _extendedPropertyStaffKey,
                Value = request.StaffId.ToString()
            });
            e.SingleValueExtendedProperties = extendedProperties.ToArray();

            return e;
        }

        async Task CreateOrUpdateTask(ExchangeConfigurationSettings settings, ExchangeItemRequest request, bool createIfNotFound, int userId)
        {
            var baseUrl = await GetActualBaseTaskUrl(userId);
            var task = await GetTaskAsync(baseUrl, userId, request.StaffId, request.CreatedOn);

            if (task != null)
            {
                await _graphHttpClient.Patch(userId, $"{baseUrl}/{task.Id}", GetTaskModel(request, task));

                _logger.Trace($"task updated [staffId={request.StaffId}/dateCreated={request.CreatedOn}]");
                return;
            }

            if (createIfNotFound)
            {
                var rm = await _graphHttpClient.Post(userId, baseUrl, GetTaskModel(request, null));
                var newTask = await rm.Content.ReadAsAsync<GraphTask>();
                await _graphResourceManager.SaveAsync(request.StaffId, request.CreatedOn, KnownExchangeResourceType.Tasks, newTask.Id);

                _logger.Trace($"task created [staffId={request.StaffId}/dateCreated={request.CreatedOn}]");
            }
        }

        async Task<GraphTask> GetTaskAsync(string baseUrl, int userId, int staffId, DateTime createdOn)
        {
            var resourceId = await _graphResourceManager.GetAsync(staffId, createdOn, KnownExchangeResourceType.Tasks);
            if (string.IsNullOrEmpty(resourceId)) return null;

            var rm = await _graphHttpClient.Get(userId, $"{baseUrl}/{resourceId}");
            if (rm.StatusCode == HttpStatusCode.NotFound)
            {
                await _graphResourceManager.DeleteAsync(staffId, createdOn, KnownExchangeResourceType.Tasks, resourceId);
                return null;
            }

            rm.EnsureSuccessStatusCode();
            return await rm.Content.ReadAsAsync<GraphTask>();
        }

        async Task<string> GetActualBaseTaskUrl(int userId)
        {
            var taskListId = await _graphTaskIdCache.Get(userId);

            return string.Format(_baseTaskUrl, taskListId);
        }

        GraphTask GetTaskModel(ExchangeItemRequest request, GraphTask e)
        {
            if (e == null)
            {
                e = new GraphTask { Id = string.Empty };
            }

            e.Title = request.Subject;
            e.Body = new GraphMessageBody
            {
                ContentType = request.IsBodyHtml ? GraphMessageBodyType.Html.ToString().ToLower() : GraphMessageBodyType.Text.ToString().ToLower(),
                Content = request.Body
            };
            e.DueDateTime = new EventDate { DateTime = request.DueDate ?? DateTime.MinValue };
            e.Importance = request.IsHighPriority ? GraphImportance.High.ToString().ToLower() : GraphImportance.Normal.ToString().ToLower();

            if (request.ReminderDate.HasValue)
            {
                var ts = e.DueDateTime.DateTime - request.ReminderDate.Value;
                e.ReminderMinutesBeforeStart = (int)ts.TotalMinutes;
                e.IsReminderOn = request.IsReminderRequired;
            }

            return e;
        }

        static IEnumerable<string> Split(string input)
        {
            return input?.Split(new[] { ';' }, StringSplitOptions.RemoveEmptyEntries) ?? Enumerable.Empty<string>();
        }

        static IEnumerable<EmailAttachment> Deserialize(string input)
        {
            if (string.IsNullOrWhiteSpace(input))
            {
                return Enumerable.Empty<EmailAttachment>();
            }

            return JsonConvert.DeserializeObject<IEnumerable<EmailAttachment>>(input);
        }

        async Task SendMessageAsync(int userId)
        {
            await _graphNotification.SendAsync(ExchangeResources.GraphAccessTokenMessage,
                                               BackgroundProcessSubType.GraphIntegrationCheckStatus,
                                               userId);
        }

        async Task<T> RefreshTokenOnExpire<T>(Func<bool, Task<T>> action, ExchangeConfigurationSettings settings, int userId, bool retry = true)
        {
            try
            {
                return await action(!retry);
            }
            catch (GraphAccessTokenNotAvailableException)
            {
                await SendMessageAsync(userId);
                throw;
            }
            catch (GraphAccessTokenExpiredException)
            {
                if (retry && !settings.RefreshTokenNotRequired)
                {
                    await _graphAccessTokenManager.RefreshAccessToken(userId, settings);

                    return await RefreshTokenOnExpire(action, settings, userId, false);
                }

                await SendMessageAsync(userId);
                throw;
            }
            catch (Exception ex)
            {
                _logger.Exception(ex, ex.Message);
                throw;
            }
        }

        async Task RefreshTokenOnExpire(Func<bool, Task> action, ExchangeConfigurationSettings settings, int userId, bool retry = true)
        {
            try
            {
                await action(!retry);
            }
            catch (GraphAccessTokenNotAvailableException)
            {
                await SendMessageAsync(userId);
                throw;
            }
            catch (GraphAccessTokenExpiredException)
            {
                if (retry && !settings.RefreshTokenNotRequired)
                {
                    await _graphAccessTokenManager.RefreshAccessToken(userId, settings);

                    await RefreshTokenOnExpire(action, settings, userId, false);

                    _logger.Trace($"Token refreshed for {userId}");
                }

                await SendMessageAsync(userId);
                throw;
            }
            catch (Exception ex)
            {
                _logger.Exception(ex, ex.Message);
                throw;
            }
        }

        string PrepareSearchUrlAsync(string url, int staffId, DateTime createdOn)
        {
            return $"{url}?$filter={GetSingleValueExtendedStringProperties(_extendedPropertyDateCreated, createdOn.ToString(KnownValues.DateFormatReminder))} and {GetSingleValueExtendedIntegerProperties(_extendedPropertyStaffKey, staffId.ToString())}&$select=id,subject";
        }

        string GetSingleValueExtendedStringProperties(string propertyName, string propertyValue)
        {
            return $"singleValueExtendedProperties/Any(ep: ep/id eq '{propertyName}' and ep/value eq '{propertyValue}')";
        }

        string GetSingleValueExtendedIntegerProperties(string propertyName, string propertyValue)
        {
            return $"singleValueExtendedProperties/Any(ep: ep/id eq '{propertyName}' and cast(ep/value, Edm.Int32) eq {propertyValue})";
        }
    }
}