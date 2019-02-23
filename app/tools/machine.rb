# frozen_string_literal: true

# 获取机器信息的相关方法
module Machine
  def self.status
    type = begin
             Machine.commond('uname').delete("\n")
           rescue StandardError
             ''
           end
    if type == 'Linux'
      return {
        system: {
          distribution: System.distribution,
          description: System.description,
          release: System.release,
          kernel: System.kernel
        },
        cpu: {
          model: CPU.model,
          number: CPU.number,
          cores: CPU.cores,
          siblings: CPU.siblings,
          mhz: CPU.mhz
        },
        memory: {
          mem: Memory::Mem.total,
          swap: Memory::Swap.total
        }
      }
    else
      return {
        system: {
          distribution: type,
          description: type,
          release: type,
          kernel: type
        },
        cpu: {
          model: '',
          number: '',
          cores: '',
          siblings: '',
          mhz: ''
        },
        memory: {
          mem: '0',
          swap: '0'
        }
      }
    end
  end

  def self.memory
    {
      mem: {
        total: Memory::Mem.total,
        used: Memory::Mem.used,
        free: Memory::Mem.free,
        usage: Memory::Mem.usage
      },
      swap: {
        total: Memory::Swap.total,
        used: Memory::Swap.used,
        free: Memory::Swap.free
      }
    }
  end

  def self.commond(commond_str)
    result = ''
    begin
      IO.popen(commond_str) do |process|
        until process.eof?
          line = process.gets
          result += line.to_s
        end
      end
    rescue StandardError => exception
      result = exception.to_s
    end
    result
  end

  # 获取系统信息
  class System
    def self.distribution
      data = Machine.commond('lsb_release -i')
      result = data.split(':').last.strip
      result
    end

    def self.description
      data = Machine.commond('lsb_release -d')
      result = data.split(':').last.strip
      result
    end

    def self.release
      data = Machine.commond('lsb_release -r')
      result = data.split(':').last.strip
      result
    end

    def self.kernel
      data = Machine.commond('uname -r')
      result = data.strip
      result
    end
  end

  # 获取CPU信息
  class CPU
    def self.model
      data = Machine.commond('cat /proc/cpuinfo | grep "model name" | sort|uniq')
      result = data.split(':').last.strip
      result
    end

    def self.number
      data = Machine.commond('cat /proc/cpuinfo | grep "physical id" | sort|uniq')
      result = data.lines.size
      result
    end

    def self.cores
      data = Machine.commond('cat /proc/cpuinfo | grep "cpu cores" | sort|uniq')
      result = data.split(':').last.strip
      result
    end

    def self.siblings
      data = Machine.commond('cat /proc/cpuinfo | grep "siblings" | sort|uniq')
      result = data.split(':').last.strip
      result
    end

    def self.mhz
      data = Machine.commond('cat /proc/cpuinfo | grep "cpu MHz" | sort|uniq')
      result = data.split(':').last.strip
      result
    end

    def self.usage
      data = Machine.commond('top -bn 2 -i -c')
      data.lines.reverse_each do |line|
        next unless line.include? 'Cpu'

        ldata = line.split(':').last.split(',')
        ldata.each do |item|
          if item.include? 'id'
            idle = item.delete('id').strip.to_f
            return 100 - idle
          end
        end
      end
    end
  end

  # 获取内存信息
  class Memory
    # 内存
    class Mem
      def self.total
        data = Machine.commond('free -b | grep "Mem"')
        result = data.split(':').last.strip.split(' ')[0]
        result
      end

      def self.used
        data = Machine.commond('free -b | grep "Mem"')
        result = data.split(':').last.strip.split(' ')[1]
        result
      end

      def self.free
        data = Machine.commond('free -b | grep "Mem"')
        result = data.split(':').last.strip.split(' ')[2]
        result
      end

      def self.usage
        data = Machine.commond('free -b | grep "Mem"')
        d0 = data.split(':').last.strip.split(' ')[0]
        d1 = data.split(':').last.strip.split(' ')[1]
        (d1.to_f / d0.to_f) * 100
      end
    end

    # 交换空间
    class Swap
      def self.total
        data = Machine.commond('free -b | grep "Swap"')
        result = data.split(':').last.strip.split(' ')[0]
        result
      end

      def self.used
        data = Machine.commond('free -b | grep "Swap"')
        result = data.split(':').last.strip.split(' ')[1]
        result
      end

      def self.free
        data = Machine.commond('free -b | grep "Swap"')
        result = data.split(':').last.strip.split(' ')[2]
        result
      end
    end
  end
end
