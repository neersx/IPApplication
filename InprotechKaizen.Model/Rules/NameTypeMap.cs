using InprotechKaizen.Model.Cases;
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Rules
{
    [Table("EVENTCONTROLNAMEMAP")]
    public class NameTypeMap
    {
        [Obsolete("For persistence only.")]
        public NameTypeMap()
        {
        }

        public NameTypeMap(ValidEvent validEvent, string applicableNameType, string substituteNameType, short sequence)
        {
            if (validEvent == null) throw new ArgumentNullException(nameof(validEvent));

            CriteriaId = validEvent.CriteriaId;
            EventId = validEvent.EventId;
            ApplicableNameTypeKey = applicableNameType;
            SubstituteNameTypeKey = substituteNameType;
            Sequence = sequence;
        }

        [Key]
        [Column("CRITERIANO", Order = 1)]
        public int CriteriaId { get; set; }

        [Key]
        [Column("EVENTNO", Order = 2)]
        public int EventId { get; set; }

        [Key]
        [Column("SEQUENCENO", Order = 3)]
        public int Sequence { get; set; }

        [Required]
        [MaxLength(3)]
        [Column("APPLICABLENAMETYPE")]
        public string ApplicableNameTypeKey { get; set; }

        [Required]
        [MaxLength(3)]
        [Column("SUBSTITUTENAMETYPE")]
        public string SubstituteNameTypeKey { get; set; }

        [Column("MUSTEXIST")]
        public bool? MustExist { get; set; }

        [Column("INHERITED")]
        public bool Inherited { get; set; }

        public virtual ValidEvent ValidEvent { get; set; }

        [ForeignKey("ApplicableNameTypeKey")]
        public virtual NameType ApplicableNameType { get; set; }

        [ForeignKey("SubstituteNameTypeKey")]
        public virtual NameType SubstituteNameType { get; set; }
    }

    public static class NameTypeMapExt
    {
        public static NameTypeMap InheritRuleFrom(this NameTypeMap nameTypeMap, NameTypeMap from)
        {
            if (nameTypeMap == null) throw new ArgumentNullException(nameof(nameTypeMap));
            if (@from == null) throw new ArgumentNullException(nameof(@from));

            nameTypeMap.Inherited = true;
            nameTypeMap.CopyFrom(from);
            return nameTypeMap;
        }

        public static void CopyFrom(this NameTypeMap nameTypeMap, NameTypeMap from, bool? isInherited = null)
        {
            if (isInherited.HasValue)
                nameTypeMap.Inherited = isInherited.Value;

            nameTypeMap.ApplicableNameTypeKey = from.ApplicableNameTypeKey;
            nameTypeMap.SubstituteNameTypeKey = from.SubstituteNameTypeKey;
            nameTypeMap.MustExist = from.MustExist;
        }

        public static int HashKey(this NameTypeMap nameTypeMap)
        {
            return new { nameTypeMap.ApplicableNameTypeKey }.GetHashCode();
        }
    }
}