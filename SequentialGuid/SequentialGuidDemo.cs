using System;
using System.Collections;
using System.Threading;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public class SequentialGuidDemo
{
    private static readonly long _ReferenceDate = new DateTime(2000, 1, 1).Ticks;
    private static readonly Sequencer _sequencer = new Sequencer();
    private static readonly SequencerLong _sequencerLong = new SequencerLong();

    private class Sequencer
    {
        public int _i;

        public int Increment()
        {
            return Interlocked.Increment(ref _i);
        }
    }

    private class SequencerLong
    {
        public long _i;

        public long Increment()
        {
            return Interlocked.Increment(ref _i);
        }
    }

    // return guid based on last six bytes
    [Microsoft.SqlServer.Server.SqlFunction]
    public static SqlGuid NewSequentialGuidOrig()
    {
        var ticks = DateTime.UtcNow.Ticks - _ReferenceDate;

        return SequentialGuidOrig.New(ticks);
    }

    // return guid based on full ticks 
    [Microsoft.SqlServer.Server.SqlFunction]
    public static SqlGuid NewSequentialGuidTicks()
    {
        var ticks = DateTime.UtcNow.Ticks - _ReferenceDate;

        return SequentialGuidTicks.New(ticks);
    }

    // return guid based on full ticks and sequencer
    [Microsoft.SqlServer.Server.SqlFunction]
    public static SqlGuid NewSequentialGuidSeqn()
    {
        var ticks = DateTime.UtcNow.Ticks - _ReferenceDate;
        var sequence = _sequencer.Increment();

        return SequentialGuidSeqn.New(ticks, sequence);
    }

    // return guid based on full ticks and long sequencer
    [Microsoft.SqlServer.Server.SqlFunction]
    public static SqlGuid NewSequentialGuidSeqnLong()
    {
        var ticks = DateTime.UtcNow.Ticks - _ReferenceDate;
        var sequence = _sequencerLong.Increment();

        return SequentialGuidSeqnLong.New(ticks, sequence);
    }

    [Microsoft.SqlServer.Server.SqlFunction]
    public static SqlInt32 Increment()
    {
        return (SqlInt32)_sequencer.Increment();
    }

    // return a row of Sequential guids based off same ticks 
    [Microsoft.SqlServer.Server.SqlFunction(FillRowMethodName = "GuidRowFillRow", TableDefinition = "SequentialGuidOrig uniqueidentifier, SequentialGuidTicks uniqueidentifier, SequentialGuidSeqn uniqueidentifier, Ticks bigint, TickBytes binary(8), Sequence int, SequenceBytes binary(4), SequentialGuidLongSeqn uniqueidentifier, SequenceLong bigint, SequenceLongBytes binary(8)")]
    public static IEnumerable NewSequentialGuids()
    {
        var results = new ArrayList(1);
        var ticks = DateTime.UtcNow.Ticks - _ReferenceDate;
        var sequence = _sequencer.Increment();
        var sequenceLong = _sequencerLong.Increment();

        results.Add(new GuidRow(SequentialGuidOrig.New(ticks), SequentialGuidTicks.New(ticks), SequentialGuidSeqn.New(ticks, sequence), ticks, sequence, SequentialGuidSeqnLong.New(ticks, sequenceLong), sequenceLong));
        return results;
    }

    private class GuidRow
    {
        public Guid SequentialGuidOrig { get; set; }
        public Guid SequentialGuidTicks { get; set; }
        public Guid SequentialGuidSeqn { get; set; }
        public long Ticks { get; set; }
        public int Sequence { get; set; }
        public Guid SequentialGuidSeqnLong { get; set; }
        public long SequenceLong { get; set; }


        public GuidRow(Guid sequentialGuidOrig, Guid sequentialGuidTicks, Guid sequentialGuidSeqn, long ticks, int sequence, Guid sequentialGuidSeqnLong, long sequenceLong)
        {
            SequentialGuidOrig = sequentialGuidOrig;
            SequentialGuidTicks = sequentialGuidTicks;
            SequentialGuidSeqn = sequentialGuidSeqn;
            Ticks = ticks;
            Sequence = sequence;
            SequentialGuidSeqnLong = sequentialGuidSeqnLong;
            SequenceLong = sequenceLong;
        }
    }

    public static void GuidRowFillRow(Object obj, out SqlGuid sequentialGuidOrig, out SqlGuid sequentialGuidTicks, out SqlGuid sequentialGuidSeqn, out SqlInt64 ticks, out SqlBinary tickBytes, out SqlInt32 sequence, out SqlBinary sequenceBytes, out SqlGuid sequentialGuidSeqnLong, out SqlInt64 sequenceLong, out SqlBinary sequenceLongBytes)
    {
        var row = (GuidRow)obj;

        sequentialGuidOrig = (SqlGuid)row.SequentialGuidOrig;
        sequentialGuidTicks = (SqlGuid)row.SequentialGuidTicks;
        sequentialGuidSeqn = (SqlGuid)row.SequentialGuidSeqn;
        ticks = (SqlInt64)row.Ticks;
        tickBytes = BitConverter.GetBytes(row.Ticks);
        sequence = (SqlInt32)row.Sequence;
        sequenceBytes = BitConverter.GetBytes(row.Sequence);
        sequentialGuidSeqnLong = (SqlGuid)row.SequentialGuidSeqnLong;
        sequenceLong = (SqlInt64)row.SequenceLong;
        sequenceLongBytes = BitConverter.GetBytes(row.SequenceLong);
    }

    private static class SequentialGuidOrig
    {
        public static Guid New(long ticks)
        {
            var guidBytes = Guid.NewGuid().ToByteArray();
            var tickBytes = BitConverter.GetBytes(ticks);

            return new Guid(new[]
            {
                guidBytes[0],
                guidBytes[1],
                guidBytes[2],
                guidBytes[3],
                guidBytes[4],
                guidBytes[5],
                guidBytes[6],
                guidBytes[7],
                guidBytes[8],
                guidBytes[9],

                // the last six bytes need to be sequential to sort in SQL Server
                tickBytes[7],
                tickBytes[6],
                tickBytes[5],
                tickBytes[4],
                tickBytes[3],
                tickBytes[2]
            });
        }
    }

    private static class SequentialGuidTicks
    {
        public static Guid New(long ticks)
        {
            var guidBytes = Guid.NewGuid().ToByteArray();
            var tickBytes = BitConverter.GetBytes(ticks);

            return new Guid(new[]
            {
                guidBytes[0],
                guidBytes[1],
                guidBytes[2],
                guidBytes[3],
                guidBytes[4],
                guidBytes[5],
                guidBytes[6],
                guidBytes[7],

                // after last 6, bytes 9 & 10 have sorting precedence. 
                tickBytes[1],
                tickBytes[0],

                // the last six bytes need to be sequential to sort in SQL Server
                tickBytes[7],
                tickBytes[6],
                tickBytes[5],
                tickBytes[4],
                tickBytes[3],
                tickBytes[2]
            });
        }
    }

    private static class SequentialGuidSeqn
    {
        public static Guid New(long ticks, int sequence)
        {
            var guidBytes = Guid.NewGuid().ToByteArray();
            var tickBytes = BitConverter.GetBytes(ticks);
            var seqBytes = BitConverter.GetBytes(sequence);

            return new Guid(new[]
            {
                guidBytes[0],
                guidBytes[1],
                guidBytes[2],
                guidBytes[3],

                // sql server presentation for this byte block is swapped
                seqBytes[1],
                seqBytes[0],

                // sql server presentation for this byte block is swapped
                seqBytes[3],
                seqBytes[2],

                // after last 6, bytes 9 & 10 have sorting precedence. 
                tickBytes[1],
                tickBytes[0],

                // the last six bytes need to be sequential to sort in SQL Server
                tickBytes[7],
                tickBytes[6],
                tickBytes[5],
                tickBytes[4],
                tickBytes[3],
                tickBytes[2]
            });
        }
    }

    private static class SequentialGuidSeqnLong
    {
        public static Guid New(long ticks, long sequence)
        {
            var guidBytes = Guid.NewGuid().ToByteArray();
            var tickBytes = BitConverter.GetBytes(ticks);
            var seqBytes = BitConverter.GetBytes(sequence);

            return new Guid(new[]
            {
                // sql server presentation for this byte block is swapped
                seqBytes[3],
                seqBytes[2],
                seqBytes[1],            
                seqBytes[0],

                // sql server presentation for this byte block is swapped
                seqBytes[5],
                seqBytes[4],

                // sql server presentation for this byte block is swapped
                seqBytes[7],
                seqBytes[6],

                // after last 6, bytes 9 & 10 have sorting precedence. 
                tickBytes[1],
                tickBytes[0],

                // the last six bytes need to be sequential to sort in SQL Server
                // http://msdn.microsoft.com/en-us/library/System.Data.SqlTypes.SqlGuid(v=vs.71).aspx
                tickBytes[7],
                tickBytes[6],
                tickBytes[5],
                tickBytes[4],
                tickBytes[3],
                tickBytes[2]
            });
        }
    }
}
