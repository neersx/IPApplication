using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Infrastructure.Security
{
    public class AuthorizationResult
    {
        public int? Id { get; set; }

        public bool Exists { get; set; }

        public bool IsUnauthorized { get; set; }

        public string ReasonCode { get; set; }

        public AuthorizationResult()
        {

        }

        public AuthorizationResult(int? id, bool exists, bool unauthorised, string reasonCode)
        {
            Id = id;
            Exists = exists;
            IsUnauthorized = unauthorised;
            ReasonCode = reasonCode;
        }

        public static AuthorizationResult NotFound(int id)
        {
            return new AuthorizationResult(id, false, true, null);
        }

        public static AuthorizationResult Unauthorized(int id, string reasonCode)
        {
            return new AuthorizationResult(id, true, true, reasonCode);
        }

        public static AuthorizationResult Authorized(int id)
        {
            return new AuthorizationResult(id, true, false, null);
        }
    }

    public static class AuthorizationResultExtensions
    {
        const string ReasonNotRequired = null;

        public static bool AllUnauthorisedOrNotExists(this Dictionary<int, AuthorizationResult> items, out int[] authorisedItemIds, out Dictionary<int, AuthorizationResult> unauthorisedResults)
        {
            var authorisedIds = items.Where(_ => !_.Value.IsUnauthorized && _.Value.Exists).Select(_ => _.Key).ToArray();

            unauthorisedResults = items.Where(_ => !authorisedIds.Contains(_.Key)).ToDictionary(k => k.Key, v => v.Value);

            authorisedItemIds = authorisedIds;

            return !authorisedIds.Any();
        }

        public static Dictionary<int, AuthorizationResult> Include(this Dictionary<int, AuthorizationResult> thisResult, Dictionary<int, AuthorizationResult> otherResult)
        {
            foreach (var r in otherResult) thisResult.Add(r.Key, r.Value);
            return thisResult;
        }

        public static Dictionary<int, AuthorizationResult> ToAuthorizationResults(this IEnumerable<int> ids, Dictionary<int, bool> queryResult, string resaonCode)
        {
            var result = new Dictionary<int, AuthorizationResult>();
            foreach (var id in ids)
            {
                if (queryResult.TryGetValue(id, out bool isUnauthorised))
                {
                    result.Add(id, new AuthorizationResult(id, true, isUnauthorised, isUnauthorised ? resaonCode : ReasonNotRequired));
                    continue;
                }

                result.Add(id, AuthorizationResult.NotFound(id));
            }
            return result;
        }

        public static Dictionary<int, AuthorizationResult> ToAuthorizationResults(this IEnumerable<int> ids, bool unauthorised, string reasonCode)
        {
            var result = new Dictionary<int, AuthorizationResult>();
            foreach (var id in ids)
            {
                result.Add(id, unauthorised
                               ? AuthorizationResult.Unauthorized(id, reasonCode)
                               : AuthorizationResult.Authorized(id));
            }
            return result;
        }
    }
}