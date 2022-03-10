using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure.Caching;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Security;

namespace InprotechKaizen.Model.Components.Security
{
    public class AuthorizationResultCache : IAuthorizationResultCache,
                                            IHandle<UserSessionStartedMessage>,
                                            IHandle<UserSessionInvalidatedMessage>,
                                            IHandle<UserSessionsInvalidatedMessage>
    {
        static bool _isDisable;

        static readonly ConcurrentDictionary<string, AuthorizationResult> Cache =
            new ConcurrentDictionary<string, AuthorizationResult>();

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

        public bool TryGetCaseAuthorizationResult(int userIdentityId, int caseId, AccessPermissionLevel minimumLevelRequested, out AuthorizationResult authorizationResult)
        {
            if (IsDisabled)
            {
                authorizationResult = null;
                return false;
            }

            return Cache.TryGetValue(GetCaseAuthorizationResultCacheKey(userIdentityId, caseId, minimumLevelRequested), out authorizationResult);
        }

        public bool TryGetNameAuthorizationResult(int userIdentityId, int nameId, AccessPermissionLevel minimumLevelRequested, out AuthorizationResult authorizationResult)
        {
            if (IsDisabled)
            {
                authorizationResult = null;
                return false;
            }

            return Cache.TryGetValue(GetNameAuthorizationResultCacheKey(userIdentityId, nameId, minimumLevelRequested), out authorizationResult);
        }

        public bool TryAddCaseAuthorizationResult(int userIdentityId, int caseId, AccessPermissionLevel minimumLevelRequested, AuthorizationResult addAuthorizationResult)
        {
            if (IsDisabled)
            {
                return false;
            }

            // it is unlikely two threads trying to get authorization result will return different authorization result.
            // even if TryAdd fails it is acceptable
            return Cache.TryAdd(GetCaseAuthorizationResultCacheKey(userIdentityId, caseId, minimumLevelRequested), addAuthorizationResult);
        }
        
        public bool TryAddNameAuthorizationResult(int userIdentityId, int nameId, AccessPermissionLevel minimumLevelRequested,
                                                  AuthorizationResult addAuthorizationResult)
        {
            if (IsDisabled)
            {
                return false;
            }

            // it is unlikely two threads trying to get authorization result will return different authorization result.
            // even if TryAdd fails it is acceptable
            return Cache.TryAdd(GetNameAuthorizationResultCacheKey(userIdentityId, nameId, minimumLevelRequested), addAuthorizationResult);
        }

        static string GetCaseAuthorizationResultCacheKey(int userIdentityId, int caseId, AccessPermissionLevel minimumLevelRequested)
        {
            return $@"{userIdentityId}:C/{caseId}/{minimumLevelRequested}";
        }

        static string GetNameAuthorizationResultCacheKey(int userIdentityId, int nameId, AccessPermissionLevel minimumLevelRequested)
        {
            return $@"{userIdentityId}:N/{nameId}/{minimumLevelRequested}";
        }
        
        public void Handle(UserSessionInvalidatedMessage message)
        {
            foreach (var key in CachedItemsForUser(message.IdentityId))
                Cache.TryRemove(key, out _);
        }

        public void Handle(UserSessionsInvalidatedMessage message)
        {
            foreach (var id in message.IdentityIds ?? new int[0])
            foreach (var key in CachedItemsForUser(id))
                Cache.TryRemove(key, out _);
        }

        public void Handle(UserSessionStartedMessage message)
        {
            foreach (var key in CachedItemsForUser(message.IdentityId))
                Cache.TryRemove(key, out _);
        }

        static IEnumerable<string> CachedItemsForUser(int userIdentity)
        {
            // this is expensive because it acquires all locks at once
            var keys = Cache.Keys.ToArray();
            var keyStartPattern = $"{userIdentity}:";
            foreach (var key in keys)
            {
                if (key.StartsWith(keyStartPattern))
                {
                    yield return key;
                }
            }
        }
    }
}