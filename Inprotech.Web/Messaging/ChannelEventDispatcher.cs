using System;
using Inprotech.Contracts.Messages.Channel;
using Inprotech.Contracts.Messages.Channel.NameConsolidation;
using Inprotech.Contracts.Messages.Channel.Time;
using Inprotech.Infrastructure.Messaging;
using ServiceStack;

namespace Inprotech.Web.Messaging
{
    public class ChannelEventDispatcher : IHandle<ChannelConnectedMessage>, IHandle<ChannelDisconnectedMessage>
    {
        const string GlobalNameChangePrefix = "globalName.change.";
        const string PolicingChangePrefix = "policing.change.";
        const string AffectedCasesPrefix = "policing.affected.cases.";
        const string NameConsolidation = "name.consolidation.status";
        const string BackgroundNotificationPrefix = "background.notification.";
        const string SearchExportContentPrefix = "search.export.content";
        const string DmsOauth2LoginPrefix = "dms.oauth2.login.";
        const string TimeRecordingPrefix = "time.recording.timerStarted";
        const string GraphOauth2LoginPrefix = "graph.oauth2.login.";

        readonly IBus _bus;

        public ChannelEventDispatcher(IBus bus)
        {
            _bus = bus;
        }

        public void Handle(ChannelConnectedMessage message)
        {
            if (message.Bindings == null)
            {
                return;
            }

            foreach (var binding in message.Bindings)
            {
                if (binding.StartsWith(GlobalNameChangePrefix, StringComparison.OrdinalIgnoreCase))
                {
                    if (int.TryParse(binding.Substring(GlobalNameChangePrefix.Length), out var caseId))
                    {
                        _bus.Publish(new GlobalNameChangeSubscribedMessage
                        {
                            ConnectionId = message.ConnectionId,
                            CaseId = caseId
                        });
                    }
                }
                else if (binding.StartsWith(PolicingChangePrefix, StringComparison.OrdinalIgnoreCase))
                {
                    if (int.TryParse(binding.Substring(PolicingChangePrefix.Length), out var caseId))
                    {
                        _bus.Publish(new PolicingChangeSubscribedMessage
                        {
                            ConnectionId = message.ConnectionId,
                            CaseId = caseId
                        });
                    }
                }
                else if (binding.StartsWith(AffectedCasesPrefix, StringComparison.OrdinalIgnoreCase))
                {
                    if (int.TryParse(binding.Substring(AffectedCasesPrefix.Length), out var requestId))
                    {
                        _bus.Publish(new PolicingAffectedCasesSubscribedMessage
                        {
                            ConnectionId = message.ConnectionId,
                            RequestId = requestId
                        });
                    }
                }
                else if (binding.EqualsIgnoreCase(NameConsolidation))
                {
                    _bus.Publish(new StatusChangeSubscribedMessage
                    {
                        ConnectionId = message.ConnectionId
                    });
                }
                else if (binding.StartsWith(BackgroundNotificationPrefix, StringComparison.OrdinalIgnoreCase))
                {
                    if (int.TryParse(binding.Substring(BackgroundNotificationPrefix.Length), out var identityId))
                    {
                        _bus.Publish(new BackgroundNotificationSubscribedMessage
                        {
                            ConnectionId = message.ConnectionId,
                            IdentityId = identityId
                        });
                    }
                }
                else if (binding.EqualsIgnoreCase(SearchExportContentPrefix))
                {
                    _bus.Publish(new SearchExportContentSubscribedMessage
                    {
                        ConnectionId = message.ConnectionId
                    });
                }
                else if (binding.StartsWith(DmsOauth2LoginPrefix, StringComparison.OrdinalIgnoreCase))
                {
                    _bus.Publish(new DmsOauth2LoginSubscribedMessage
                    {
                        ConnectionId = message.ConnectionId
                    });
                }
                else if (binding.StartsWith(GraphOauth2LoginPrefix, StringComparison.OrdinalIgnoreCase))
                {
                    _bus.Publish(new GraphOauth2LoginSubscribedMessage
                    {
                        ConnectionId = message.ConnectionId
                    });
                }
                else if (binding.StartsWith(TimeRecordingPrefix, StringComparison.OrdinalIgnoreCase))
                {
                    if (int.TryParse(binding.Substring(TimeRecordingPrefix.Length), out var identityId))
                    {
                        _bus.Publish(new ActiveTimerSubscribedMessage
                        {
                            ConnectionId = message.ConnectionId,
                            IdentityId = identityId
                        });
                    }
                }
            }
        }

        public void Handle(ChannelDisconnectedMessage message)
        {
            _bus.Publish(new GlobalNameChangeUnsubscribedMessage
            {
                ConnectionId = message.ConnectionId
            });

            _bus.Publish(new PolicingChangeUnsubscribedMessage
            {
                ConnectionId = message.ConnectionId
            });

            _bus.Publish(new PolicingAffectedCasesUnsubscribedMessage
            {
                ConnectionId = message.ConnectionId
            });

            _bus.Publish(new StatusChangeUnsubscribedMessage
            {
                ConnectionId = message.ConnectionId
            });

            _bus.Publish(new BackgroundNotificationUnsubscribedMessage
            {
                ConnectionId = message.ConnectionId
            });

            _bus.Publish(new SearchExportContentUnsubscribedMessage
            {
                ConnectionId = message.ConnectionId
            });

            _bus.Publish(new DmsOauth2LoginUnsubscribedMessage
            {
                ConnectionId = message.ConnectionId
            });

            _bus.Publish(new GraphOauth2LoginUnsubscribedMessage
            {
                ConnectionId = message.ConnectionId
            });

            _bus.Publish(new ActiveTimerUnsubscribedMessage
            {
                ConnectionId = message.ConnectionId
            });
        }
    }
}