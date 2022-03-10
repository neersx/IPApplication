using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public interface IDatesAligner
    {
        IEnumerable<DatePair<PtoDateInfo, short?>> Align(IEnumerable<Date<PtoDateInfo>> list1, IEnumerable<Date<short>> list2);
    }

    public class DatesAligner : IDatesAligner
    {
        public IEnumerable<DatePair<PtoDateInfo, short?>> Align(IEnumerable<Date<PtoDateInfo>> list1,
            IEnumerable<Date<short>> list2)
        {
            if (list1 == null) throw new ArgumentNullException("list1");
            if (list2 == null) throw new ArgumentNullException("list2");

            var l1 = list1.ToArray();
            var l2 = list2.ToArray();

            var a = new Queue<Date<PtoDateInfo>>(l1);
            var b = new Queue<Date<short>>(l2);

            if (!a.Select(_ => _.DateTime).Intersect(l2.Select(_ => _.DateTime)).Any())
                return MixedIn(a, b);

            return Aligned(l1, l2);
        }

        static IEnumerable<DatePair<PtoDateInfo, short?>> Aligned(IEnumerable<Date<PtoDateInfo>> a, IEnumerable<Date<short>> b)
        {
            var result = new List<DatePair<PtoDateInfo, short?>>();
            var worklhs = a.ToArray(); /* most likely PTO dates */
            var workrhs = b.ToArray(); /* most likely Inprotech Case Event dates and cycles */
            var collisions =
                new Queue<DateTime?>(worklhs.Select(_ => _.DateTime).Intersect(workrhs.Select(_ => _.DateTime)));

            while (collisions.Any())
            {
                var current = new List<DatePair<PtoDateInfo, short?>>();

                var collision = collisions.Dequeue();
                var collidedLhsRef = worklhs.First(_ => _.DateTime == collision).Ref;
                var collidedRhs = workrhs.FirstOrDefault(_ => _.DateTime == collision);
                var collisionCycle = collidedRhs == null ? (short?) null : collidedRhs.Ref;

                if (!collisions.Any() && collisionCycle == null)
                    collisionCycle = NextCycleFrom(result);

                var lhs = new Stack<Date<PtoDateInfo>>(worklhs.TakeWhile(_ => _.DateTime != collision));
                var rhs = new Stack<Date<short>>(workrhs.Any(_ => _.DateTime == collision)
                    ? workrhs.TakeWhile(_ => _.DateTime != collision)
                    : Enumerable.Empty<Date<short>>());

                worklhs = worklhs.RemoveRange(0, lhs.Count() + 1);
                workrhs = workrhs.RemoveRange(0, rhs.Count() + (collidedRhs != null ? 1 : 0)).ToArray();

                while (lhs.Any() || rhs.Any())
                {
                    var l = lhs.Any() ? lhs.Pop() : null;
                    var r = rhs.Any() ? rhs.Pop() : null;

                    current.Insert(0, new DatePair<PtoDateInfo, short?>
                                      {
                                          DateTimeLhs = l == null ? null : l.DateTime,
                                          DateTimeRhs = r == null ? null : r.DateTime,
                                          RefLhs = l == null ? null : l.Ref,
                                          RefRhs = r == null ? null : (short?) r.Ref
                                      });
                }

                current.Add(new DatePair<PtoDateInfo, short?>
                            {
                                DateTimeLhs = collision,
                                DateTimeRhs = collidedRhs != null ? collidedRhs.DateTime : null,
                                RefLhs = collidedLhsRef,
                                RefRhs = collisionCycle
                            });

                result.AddRange(current);
            }

            var lhs2 = new Queue<Date<PtoDateInfo>>(worklhs);
            var rhs2 = new Queue<Date<short>>(workrhs);
            var cycle = NextCycleFrom(result);

            while (lhs2.Any() || rhs2.Any())
            {
                var lhs = lhs2.Any() ? lhs2.Dequeue() : null;
                var rhs = rhs2.Any() ? rhs2.Dequeue() : null;

                if (rhs != null)
                    cycle = rhs.Ref;

                result.Add(new DatePair<PtoDateInfo, short?>
                           {
                               DateTimeLhs = lhs == null ? null : lhs.DateTime,
                               DateTimeRhs = rhs == null ? null : rhs.DateTime,
                               RefLhs = lhs == null ? null : lhs.Ref,
                               RefRhs = cycle++
                           });
            }

            return result;
        }

        static IEnumerable<DatePair<PtoDateInfo, short?>> MixedIn(
            Queue<Date<PtoDateInfo>> a, Queue<Date<short>> b)
        {
            short cycle = 1;

            while (true)
            {
                var lhs = a.Any() ? a.Dequeue() : null;
                var rhs = b.Any() ? b.Dequeue() : null;

                if (rhs != null)
                    cycle = rhs.Ref;

                yield return new DatePair<PtoDateInfo, short?>
                             {
                                 DateTimeLhs = lhs == null ? null : lhs.DateTime,
                                 DateTimeRhs = rhs == null ? null : rhs.DateTime,
                                 RefLhs = lhs == null ? null : lhs.Ref,
                                 RefRhs = cycle++
                             };

                if (!a.Any() && !b.Any())
                    break;
            }
        }

        static short NextCycleFrom(IEnumerable<DatePair<PtoDateInfo, short?>> results)
        {
            return (short) (results.Where(_ => _.RefRhs.HasValue).Max(_ => _.RefRhs.Value) + 1);
        }
    }

    public class Date<T>
    {
        public DateTime? DateTime { get; set; }

        public T Ref { get; set; }
    }

    public class DatePair<T, TK>
    {
        public DateTime? DateTimeLhs { get; set; }

        public T RefLhs { get; set; }

        public DateTime? DateTimeRhs { get; set; }

        public TK RefRhs { get; set; }
    }

    public class PtoDateInfo
    {
        public string Ref { get; set; }

        public string Description { get; set; }
    }
}