using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Ede.DataMapping;

namespace InprotechKaizen.Model.Components.Cases.Comparison.DataMapping
{
    public class Source
    {
        public int TypeId { get; set; }

        public string Code { get; set; }

        public string Description { get; set; }
    }

    public class MappedValue
    {
        public MappedValue(Source source, Mapping mapping)
        {
            if (mapping == null) throw new ArgumentNullException(nameof(mapping));
            Source = source ?? throw new ArgumentNullException(nameof(source));
            Output = mapping.OutputValue;
        }

        protected MappedValue(Source source)
        {
            Source = source ?? throw new ArgumentNullException(nameof(source));
        }

        public Source Source { get; protected set; }

        public string Output { get; protected set; }
    }

    public class FailedSource : Source
    {
        public FailedSource(Source source, string structureName)
        {
            if (source == null) throw new ArgumentNullException(nameof(source));

            TypeId = source.TypeId;
            Code = source.Code;
            Description = source.Description;
            StructureName = structureName;
        }

        public string StructureName { get; }
    }

    public class FailedMapping : MappedValue
    {
        public FailedMapping(Source source, string structureName)
            : base(new FailedSource(source, structureName))
        {
        }
    }

    [SuppressMessage("Microsoft.Usage", "CA2237:MarkISerializableTypesWithSerializable")]
    [SuppressMessage("Microsoft.Design", "CA1032:ImplementStandardExceptionConstructors")]
    public class FailedMappingException : Exception
    {
        public FailedMappingException(IEnumerable<FailedSource> dataSource)
        {
            DataSource = dataSource;
        }

        public IEnumerable<FailedSource> DataSource { get; }
    }
}