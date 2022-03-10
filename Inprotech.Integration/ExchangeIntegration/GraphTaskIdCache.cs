using System.Collections.Concurrent;
using System.Net.Http;
using System.Threading.Tasks;

namespace Inprotech.Integration.ExchangeIntegration
{
    public interface IGraphTaskIdCache
    {
        Task<string> Get(int userId);
        Task<bool> Remove(int userId);
    }

    public class GraphTaskIdCache : IGraphTaskIdCache
    {
        static readonly ConcurrentDictionary<int, string> LifeTimeDictionaryToken = new ConcurrentDictionary<int, string>();
        readonly IGraphHttpClient _graphHttpClient;

        public GraphTaskIdCache(IGraphHttpClient graphHttpClient)
        {
            _graphHttpClient = graphHttpClient;
        }

        public async Task<string> Get(int userId)
        {
            if (LifeTimeDictionaryToken.TryGetValue(userId, out var taskListId))
            {
                return taskListId;
            }

            var res = await _graphHttpClient.Get(userId, "/v1.0/me/todo/lists/Tasks");
            res.EnsureSuccessStatusCode();
            var graphTaskList = await res.Content.ReadAsAsync<GraphTaskList>();

            LifeTimeDictionaryToken.AddOrUpdate(userId,
                                                graphTaskList.Id,
                                                (k, v) =>
                                                {
                                                    v = graphTaskList.Id;
                                                    return v;
                                                });

            return graphTaskList.Id;
        }

        public Task<bool> Remove(int userId)
        {
            return Task.FromResult(LifeTimeDictionaryToken.TryRemove(userId, out _));
        }
    }

    public class GraphTaskList
    {
        public string DisplayName { get; set; }

        public string Id { get; set; }
    }
}