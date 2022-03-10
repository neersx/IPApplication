using System;
using System.Collections.Generic;
using System.Linq;

namespace InprotechKaizen.Model.Components.Policing.Monitoring
{
    public class InterimSummaryRecord
    {
        internal string Status { get; set; }

        internal PolicingDuration IdleFor { get; set; }
        internal int Count { get; set; }
    }

    public static class PolicingQueueKnownStatus
    {
        public const string All = "all";
        public const string Progressing = "progressing";
        public const string RequiresAttention = "requires-attention";
        public const string OnHold = "on-hold";

        public static string[] MappedStatus(string byStatus)
        {
            switch (byStatus)
            {
                case Progressing:
                    return new[] {PolicingItemStatus.InProgress, PolicingItemStatus.WaitingToStart};
                case RequiresAttention:
                    return new[] {PolicingItemStatus.Failed, PolicingItemStatus.Blocked, PolicingItemStatus.Error};
                case OnHold:
                    return new[] {PolicingItemStatus.OnHold};
                case All:
                    return MappedStatus(Progressing).Concat(MappedStatus(RequiresAttention)).Concat(MappedStatus(OnHold)).ToArray();
            }
            throw new NotSupportedException("Unable to find internal types by status :" + byStatus);
        }
    }

    public static class PolicingItemStatus
    {
        public const string InProgress = "in-progress";
        public const string WaitingToStart = "waiting-to-start";
        public const string OnHold = "on-hold";
        public const string Failed = "failed";
        public const string Blocked = "blocked";
        public const string Error = "in-error";
    }

    internal enum PolicingDuration
    {
        Fresh,
        Tolerable,
        Stuck
    }

    public static class InterimSummaryRecordExtension
    {
        public static IEnumerable<InterimSummaryRecord> Fresh(this IEnumerable<InterimSummaryRecord> interimRecords)
        {
            return interimRecords.Where(_ => _.IdleFor == PolicingDuration.Fresh);
        }

        public static IEnumerable<InterimSummaryRecord> Tolerable(this IEnumerable<InterimSummaryRecord> interimRecords)
        {
            return interimRecords.Where(_ => _.IdleFor == PolicingDuration.Tolerable);
        }

        public static IEnumerable<InterimSummaryRecord> Old(this IEnumerable<InterimSummaryRecord> interimRecords)
        {
            return interimRecords.Where(_ => _.IdleFor == PolicingDuration.Stuck);
        }

        public static IEnumerable<InterimSummaryRecord> WaitingToStart(this IEnumerable<InterimSummaryRecord> interimRecords)
        {
            return interimRecords.Where(_ => _.Status == PolicingItemStatus.WaitingToStart);
        }

        public static IEnumerable<InterimSummaryRecord> Blocked(this IEnumerable<InterimSummaryRecord> interimRecords)
        {
            return interimRecords.Where(_ => _.Status == PolicingItemStatus.Blocked);
        }

        public static IEnumerable<InterimSummaryRecord> InProgress(this IEnumerable<InterimSummaryRecord> interimRecords)
        {
            return interimRecords.Where(_ => _.Status == PolicingItemStatus.InProgress);
        }

        public static IEnumerable<InterimSummaryRecord> Failed(this IEnumerable<InterimSummaryRecord> interimRecords)
        {
            return interimRecords.Where(_ => _.Status == PolicingItemStatus.Failed);
        }

        public static IEnumerable<InterimSummaryRecord> OnHold(this IEnumerable<InterimSummaryRecord> interimRecords)
        {
            return interimRecords.Where(_ => _.Status == PolicingItemStatus.OnHold);
        }

        public static IEnumerable<InterimSummaryRecord> InError(this IEnumerable<InterimSummaryRecord> interimRecords)
        {
            return interimRecords.Where(_ => _.Status == PolicingItemStatus.Error);
        }

        public static int Sum(this IEnumerable<InterimSummaryRecord> interimRecords)
        {
            return interimRecords.Sum(_ => _.Count);
        }
    }
}