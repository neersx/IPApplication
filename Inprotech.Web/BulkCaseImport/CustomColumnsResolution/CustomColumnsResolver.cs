using System;
using System.Collections.Generic;
using System.Linq;
using CPAXML;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Ede.DataMapping;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.BulkCaseImport.CustomColumnsResolution
{
    public interface ICustomColumnsResolver
    {
        bool ResolveCustomColumns(CaseDetails details, JToken @case, out string duplicateMapping);
    }

    public class CustomColumnsResolver : ICustomColumnsResolver
    {
        readonly IDbContext _dbContext;
        readonly IStructureMappingResolver _structureMappingResolver;

        static readonly int[] StructuresToConsider =
        {
            KnownMapStructures.Events, KnownMapStructures.NumberType, KnownMapStructures.NameType, KnownMapStructures.TextType
        };

        bool _loaded;
        List<Mapping> _rawEdeMappings;

        public CustomColumnsResolver(IDbContext dbContext, IStructureMappingResolver structureMappingResolver)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (structureMappingResolver == null) throw new ArgumentNullException("structureMappingResolver");

            _dbContext = dbContext;
            _structureMappingResolver = structureMappingResolver;
        }

        void Prepare()
        {
            if (_loaded)
                return;

            _rawEdeMappings = _dbContext.Set<Mapping>()
                                        .Where(_ => _.DataSourceId == (int)KnownExternalSystemIds.Ede && StructuresToConsider.Contains(_.StructureId)).ToList();

            _loaded = true;
        }

        public bool ResolveCustomColumns(CaseDetails details, JToken @case, out string duplicateMappingError)
        {
            duplicateMappingError = string.Empty;
            Prepare();

            if (!_rawEdeMappings.Any())
                return true;

            var actionList = new Dictionary<int, Action<string, object>>
            {
                {KnownMapStructures.Events, details.CreateEvent},
                {KnownMapStructures.NumberType, details.CreateNumber},
                {KnownMapStructures.NameType, details.CreateName},
                {KnownMapStructures.TextType, details.CreateText}
            };

            foreach (var structureType in StructuresToConsider)
            {
                string duplicateMapping;
                Action<string, object> setDataAction;

                if (actionList.TryGetValue(structureType, out setDataAction) && !_structureMappingResolver.Resolve(@case, _rawEdeMappings, structureType, setDataAction, out duplicateMapping))
                    {
                        duplicateMappingError = SetError(duplicateMapping);
                        return false;
                    }

                if (!@case.Children().Any())
                    break;
            }

            return true;
        }

        static string SetError(string duplicateMapping)
        {
            return string.Format(Resources.ImportCasesDuplicateMapping, duplicateMapping);
        }
    }
}