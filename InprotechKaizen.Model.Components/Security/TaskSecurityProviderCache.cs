using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure.Caching;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Security;

namespace InprotechKaizen.Model.Components.Security
{
    public interface ITaskSecurityProviderCache : IDisableApplicationCache
    {
        bool IsEmpty { get; }

        void Clear();

        IDictionary<short, ValidSecurityTask> Resolve(Func<int, IDictionary<short, ValidSecurityTask>> valuesFactory, int userIdentityId);
    }

    public class TaskSecurityProviderCache : ITaskSecurityProviderCache,
                                             IHandle<UserSessionStartedMessage>,
                                             IHandle<UserSessionInvalidatedMessage>,
                                             IHandle<UserSessionsInvalidatedMessage>
    {
        static bool _isDisable;

        static readonly ConcurrentDictionary<int, IDictionary<short, ValidSecurityTask>> Cache =
            new ConcurrentDictionary<int, IDictionary<short, ValidSecurityTask>>();

        public void Handle(UserSessionInvalidatedMessage message)
        {
            Cache.TryRemove(message.IdentityId, out _);
        }

        public void Handle(UserSessionsInvalidatedMessage message)
        {
            foreach (var id in message.IdentityIds ?? new int[0])
                Cache.TryRemove(id, out _);
        }

        public void Handle(UserSessionStartedMessage message)
        {
            Cache.TryRemove(message.IdentityId, out _);
        }

        public bool IsEmpty => Cache.IsEmpty;

        public bool IsDisabled
        {
            get => _isDisable;
            set => _isDisable = value;
        }

        public void Clear()
        {
            Cache.Clear();
        }

        public IDictionary<short, ValidSecurityTask> Resolve(Func<int, IDictionary<short, ValidSecurityTask>> valuesFactory, int userIdentityId)
        {
            return IsDisabled
                ? valuesFactory(userIdentityId)
                : Cache.GetOrAdd(userIdentityId, x => valuesFactory(userIdentityId));
        }
    }
}