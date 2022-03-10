using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Ede.Extensions;
using InprotechKaizen.Model.Persistence;
using Entity = InprotechKaizen.Model.Ede.DataMapping;

namespace Inprotech.Web.Configuration.Ede.DataMapping.Mappings
{
    public interface IMappingPersistence
    {
        bool Add(Mapping mapping, int structureId, int systemId, out IEnumerable<string> errors, out int? newId);

        bool Update(Mapping mapping, int structureId, int systemId, out IEnumerable<string> errors);

        void Delete(int mappingId);
    }

    public class MappingPersistence : IMappingPersistence
    {
        readonly IDbContext _dbContext;
        readonly IMappingHandlerResolver _mappingHandlerResolver;

        public MappingPersistence(IDbContext dbContext, IMappingHandlerResolver mappingHandlerResolver)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (mappingHandlerResolver == null) throw new ArgumentNullException("mappingHandlerResolver");

            _dbContext = dbContext;
            _mappingHandlerResolver = mappingHandlerResolver;
        }

        public bool Add(Mapping mapping, int structureId, int systemId, out IEnumerable<string> errors, out int? newId)
        {
            if (mapping == null) throw new ArgumentNullException("mapping");

            var args = Resolve(systemId, structureId);
            newId = null;
            if (string.IsNullOrWhiteSpace(mapping.InputDesc))
            {
                errors = CreateMandatoryValidationError("description");
                return false;
            }

            if (_dbContext.Set<Entity.Mapping>().For(structureId, systemId)
                .WithInputCodeOrDescription(mapping.InputDesc).Any())
            {
                errors = CreateUniqueValidationError(mapping.InputDesc);
                return false;
            }

            var mappingHandler = _mappingHandlerResolver.Resolve(structureId);
            if (mappingHandler.TryValidate(args.DataSource, args.MapStructure, mapping, out errors))
            {
                var newMapping = _dbContext.Set<Entity.Mapping>().Add(
                    new Entity.Mapping
                    {
                        InputDescription = HttpUtility.HtmlEncode(mapping.InputDesc),
                        OutputValue = mapping.NotApplicable ? null : mapping.OutputValueId,
                        IsNotApplicable = mapping.NotApplicable,
                        DataSource = args.DataSource,
                        MapStructure = args.MapStructure
                    });

                _dbContext.SaveChanges();
                newId = newMapping.Id;
                return true;
            }
            return false;
        }

        public bool Update(Mapping mapping, int structureId, int systemId, out IEnumerable<string> errors)
        {
            if (mapping == null) throw new ArgumentNullException("mapping");

            var args = Resolve(systemId, structureId);
            var m = _dbContext.Set<Entity.Mapping>().FirstOrDefault(_ => _.Id == mapping.Id);
            if (m == null)
                throw new HttpException((int)HttpStatusCode.NotFound, "Mapping could not be found");

            if (string.IsNullOrWhiteSpace(mapping.InputDesc))
            {
                errors = CreateMandatoryValidationError("description");
                return false;
            }

            if (_dbContext.Set<Entity.Mapping>().For(structureId, systemId)
                .WithInputCodeOrDescription(mapping.InputDesc)
                .Any(_ => _.Id != mapping.Id))
            {
                errors = CreateUniqueValidationError(mapping.InputDesc);
                return false;
            }

            var mappingHandler = _mappingHandlerResolver.Resolve(structureId);
            if (mappingHandler.TryValidate(args.DataSource, args.MapStructure, mapping, out errors))
            {
                m.InputCode = null;
                m.InputDescription = mapping.InputDesc;
                m.IsNotApplicable = mapping.NotApplicable;
                m.OutputEncodedValue = null;
                m.OutputCodeId = null;
                m.OutputValue = mapping.NotApplicable ? null : mapping.OutputValueId;

                _dbContext.SaveChanges();
                return true;
            }
            return false;
        }

        public void Delete(int mappingId)
        {
            var m = _dbContext.Set<Entity.Mapping>().FirstOrDefault(_ => _.Id == mappingId);
            if (m == null)
                throw new HttpException((int)HttpStatusCode.NotFound, "Mapping could not be found");

            _dbContext.Set<Entity.Mapping>().Remove(m);
            _dbContext.SaveChanges();
        }

        dynamic Resolve(int systemId, int structureId)
        {
            var mapStructure = _dbContext.Set<Entity.MapStructure>()
                .SingleOrDefault(_ => _.Id == structureId);

            var source = _dbContext.Set<Entity.DataSource>()
                .SingleOrDefault(_ => _.SystemId == systemId);

            if (mapStructure == null || source == null)
                throw new ArgumentException("Valid datasource and structure must be provided");

            return new
            {
                DataSource = source,
                MapStructure = mapStructure
            };
        }

        static IEnumerable<string> CreateUniqueValidationError(string messageCode)
        {
            return new[]
                   {
                      string.Format(Resources.DataMappingDescriptionNotUnique, HttpUtility.HtmlEncode(messageCode))
                   };
        }

        static IEnumerable<string> CreateMandatoryValidationError(string messageCode)
        {
            return new[]
            {
                string.Format(Resources.DataMappingDescriptionMandatory, HttpUtility.HtmlEncode(messageCode))
            };
        }
    }
}