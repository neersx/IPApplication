using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Contracts;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.System.Compatibility
{
    public interface IStoredProcedureParameterHandler
    {
        void Handle(string procedureName, IDictionary<string, object> parameters);
    }

    public class StoredProcedureParameterHandler : IStoredProcedureParameterHandler
    {
        readonly ILogger<StoredProcedureParameterHandler> _logger;
        readonly ISqlHelper _sqlHelper;

        static readonly ConcurrentDictionary<string, string[]> CompatibilityParametersMap = new();

        public StoredProcedureParameterHandler(ILogger<StoredProcedureParameterHandler> logger, ISqlHelper sqlHelper)
        {
            _logger = logger;
            _sqlHelper = sqlHelper;
        }

        public void Handle(string procedureName, IDictionary<string, object> parameters)
        {
            var parametersInProcedure = CompatibilityParametersMap.GetOrAdd(procedureName, x =>
            {
                _logger.Trace($"Deriving parameters for {procedureName}");
                return _sqlHelper.DeriveParameters(procedureName).Select(_ => _.Key).ToArray();
            });

            var incompatibleParameters = parameters.Keys.Except(parametersInProcedure).ToArray();

            foreach (var incompatibleParameter in incompatibleParameters)
            {
                parameters.Remove(incompatibleParameter);

                _logger.Trace($"{incompatibleParameter} removed before calling {procedureName}");
            }
        }
    }
}