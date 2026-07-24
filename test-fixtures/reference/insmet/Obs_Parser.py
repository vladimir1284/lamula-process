'''
Created on 11/01/2013

@author: vladimir
'''

import struct, zlib, pylab
from datetime import datetime, timedelta
from matplotlib import pyplot, cbook
#from _pyio import StringIO


OLE_TIME_ZERO   = datetime(1899, 12, 30, 0, 0, 0) # win32 time
HEADER_SIZE     = 84 # Bytes
CHANNEL_SIZE    = 32 # Bytes
PPI_DESC_SIZE   = 28 # Bytes
PPI_HEADER_SIZE = 12 # Bytes

dRadar = {0:'rdNone', 1:'rdLaBajada', 2:'rdPuntaDelEste', 3:'rdCasablanca', 
          4:'rdPicoSanJuan', 5:'rdCamaguey', 6:'rdPilon', 7:'rdGranPiedra', 
          8:'rdMcGill', 9:'rdRoma', 10:'rdCP2_SCMS', 11:'rdHolguin', 
          12:'rdVenMaracaibo', 13:'rdVenJeremba', 14:'rdVenGuasdualito', 
          15:'rdVenAyacucho', 16:'rdVenCarupano', 17:'rdVenKarum', 
          18:'rdVenSantaElena', 19:'rdVenGuri', 20:'rdCamaguey1'}

dMeasure = {0:'unNone', 1:'unDB', 2:'unDBZ', 3:'unMMH', 4:'unMS', 5:'unMM', 
            6:'unM', 7:'unKM', 8:'unKGM', 9:'unZDR', 10:'unPDP', 11:'unRho', 
            12:'unKDP', 13:'unGCP', 14:'unTID', 15:'unM2S2', 16:'unSW'}
            
class Obs_Parser:
    '''
    classdocs
    '''


    def __init__(self,filename, bf = False):
        '''
        Constructor
        '''
        # Loading File Header
        if not(bf):
            f = file(filename, 'r')
            self.s = f.read()
            f.close()
        else:
            self.s = filename # Already a file object
            
        
        
        self.Header = VestaFileHeader(self.s)
        
        # PPI locations in binary file
        loc_end = 4*self.Header.ppi_count+HEADER_SIZE
        locations = struct.unpack(str(self.Header.ppi_count) + 
                                       'I', self.s[HEADER_SIZE:loc_end])
        self.locations =[ location for location in locations ]
        
        # Channels Description
        self.chanels = []
        for i in xrange(self.Header.channel_count):
            self.chanels.append(ChannelDesc(
                                    self.s[loc_end + i*CHANNEL_SIZE:]))
            #self.chanels[i].print_channel()
        
        # PPI headers and Data
        self.ppis_header = []
        self.ppis = []
        for i,location in enumerate(self.locations):
            self.ppis_header.append(Vesta_PPI_Header(self.s,location))
            
            size = self.ppis_header[i].packed_Size
            pos  = location+PPI_DESC_SIZE+PPI_HEADER_SIZE
            
            # Decompress
            if self.ppis_header[i].pack_Method == 'pmZLib':
                self.ppis.append(zlib.decompress(self.s[pos:pos+size]))
            else:
                print 'Unhadled compression method'
            if self.ppis[i].__len__()!=self.ppis_header[i].unpacked_Size:
                class CorruptFile_Exception(BaseException):
                    pass
                raise CorruptFile_Exception(
                                        'Error decompressing .obs file')
            
            chan    = self.chanels[
                                self.ppis_header[i].Description.channel]
            sectors = chan.num_of_sectors
            gates   = chan.number_of_cells 
            size = sectors*gates
            self.ppis[i] = pylab.array(struct.unpack(str(size)+
                                            'B',self.ppis[i][:size]))
            
            # 2D Data array radial sectors contains range gates
            self.ppis[i] = self.ppis[i].reshape((sectors,gates))
            # From .obs code to value
            if self.ppis_header[i].Description.meassurement == 'unDBZ':
                self.ppis[i] -= 80
                    
            if (self.ppis_header[i].Description.meassurement=='unMS' or
                self.ppis_header[i].Description.meassurement == 'unSW'):
                self.ppis[i] = (self.ppis[i] -128)/2.
                if self.ppis_header[i].Description.meassurement=='unMS':
                    self.ppis[i] *= -1 #TODO speed sign correction
            
    
    def dB2dBZ(self, index):
        '''
        Converts dB ppi to dBZ ppi
        '''
        if self.ppis_header[index].Description.meassurement != 'unDB':
            return -1
        
        chann = self.chanels[self.ppis_header[index].Description.channel]
        ncell = chann.number_of_cells
        nrays = chann.num_of_sectors
        
        cellLength = chann.cell_lenght/1000. # km
        correction = 20*pylab.log10(pylab.linspace(
                                        cellLength,ncell*cellLength,ncell))
        correction[correction < 0] = 0
        correction = pylab.meshgrid(correction,pylab.zeros(nrays))[0]
        
        PM = chann.met_potential
        # Result in dBZ
        ppiDBZ = self.ppis[index] + correction + PM
        ppiDBZ[self.ppis[index]==0] = -80 # No data
        return ppiDBZ

    
    def getCuts(self):
        '''
        Returns a collection of cuts type and angle
        found in the observation design
        '''
        cuts = []
        angles  = [int(ppiHeader.Description.angle*10)/10. 
                                        for ppiHeader in self.ppis_header]
        batch = False
        
        for (i,header) in enumerate(self.ppis_header):
            if header.Description.meassurement == 'unDB':
                # CS mode
                cuts.append((1,angles[i]))
                
            if header.Description.meassurement == 'unDBZ':
                if len(self.ppis_header) > i+1: # Next ppi exists
                    if (self.ppis_header[i+1].Description.meassurement == 
                        'unMS') and (angles[i] == angles[i+1]):
                        # 3 moments for elevation
                        if header.Description.time == \
                                    self.ppis_header[i+1].Description.time:
                            # BATCH mode
                            cuts.append((4,angles[i]))
                            batch = True
                        else:
                            # split cut mode
                            cuts.append((1,angles[i]))
                    else:
                        # CS mode
                        cuts.append((1,angles[i]))
                else: # Next ppi doesn't exists
                    # CS mode
                    cuts.append((1,angles[i]))                    
            elif header.Description.meassurement == 'unMS':
                if batch:
                    batch = False
                elif len(self.ppis_header) > i+2: # Next Z ppi exists
                    if (self.ppis_header[i+2].Description.meassurement 
                        == 'unDBZ') and (angles[i] == angles[i+2]):
                        # 3 moments for elevation
                        if header.Description.time == \
                                    self.ppis_header[i+2].Description.time:
                            # BATCH mode
                            cuts.append((4,angles[i]))
                        else:
                            # split cut mode
                            cuts.append((2,angles[i]))
                    else:
                        # CD mode
                        cuts.append((2,angles[i])) 
                else: # Next ppi doesn't exists
                    # CD mode
                    cuts.append((2,angles[i]))   
        
        return cuts
                        
    
    def save2File(self, filename, Template):
        f = file(filename,'w') 
        
        f.write(self.Header.toStream())
        # Skeep locations by now
        f.seek(4*self.Header.ppi_count,1)
        
        for chanel in self.chanels:
            f.write(chanel.toStream())
            
        # Actually save ppis   
        for i in xrange(len(self.locations)):
            self.locations[i] = f.tell()
            if not(Template):
                if self.ppis_header[i].Description.meassurement=='unDBZ':
                    ppi = self.ppis[i] + 80
                        
                if (self.ppis_header[i].Description.meassurement=='unMS' or
                    self.ppis_header[i].Description.meassurement=='unSW'):
                    ppi = 2*self.ppis[i] + 128
                    ppi[ppi>255]    = 255
                    ppi[ppi<0]      = 0
            else:
                ppi = self.ppis[i]
                
            chan    = self.chanels[
                                self.ppis_header[i].Description.channel]
            sectors = chan.num_of_sectors
            gates   = chan.number_of_cells 
            size = sectors*gates
            unCompressData = struct.pack(str(size)+'B',*ppi.flatten())
            
            # Estos ceros completan los 460km
            numZeros = self.ppis_header[i].unpacked_Size - size
            if numZeros > 0:
                nullBytes = pylab.zeros(numZeros)
                unCompressData += struct.pack(str(numZeros)+'B',
                                                        *nullBytes)
                        
            stream = zlib.compress(unCompressData)
            self.ppis_header[i].packed_Size = len(stream)
            
            f.write(self.ppis_header[i].toStream())
            f.write(stream)
            
        # Write locations now
        f.seek(HEADER_SIZE,0)
        for location in self.locations:
            f.write(struct.pack('I',location))
            
        f.close()
        
        
    def plot_ppi(self,index = 0,ax = None, data = None):
        if ax == None:
            fig = pylab.figure()                
            ax = pylab.axes(axisbg = 'k', polar=True)
        
        if data == None:
            data = self.ppis[index]
        
        chan    = self.chanels[
                            self.ppis_header[index].Description.channel]
        start_range = chan.cell_lenght/2.
        stop_range  = start_range + \
                        chan.cell_lenght*chan.number_of_cells
        
        ranges = pylab.linspace(start_range, stop_range, 
                                    chan.number_of_cells)
        
        start_ang   = self.ppis_header[index].Description.start_az
        stop_ang    = self.ppis_header[index].Description.finish_az
        
        angles = pylab.linspace(start_ang, stop_ang, 
                        self.ppis_header[index].Description.sectorCount)
        
        rad, theta = pylab.meshgrid(ranges/1000., 
                                        (90-angles)*pylab.pi/180)
        X = theta
        Y = rad 

        ax.pcolormesh(X,Y,data,cmap=pyplot.cm.gray) #@UndefinedVariable
#         pylab.title('pulse: %s, elev: %.2f, unit: %s' % (chan.pulse, 
#                     self.ppis_header[index].Description.angle,
#                     self.ppis_header[index].Description.meassurement))
#         pylab.savefig('../ppi_%i.png' % index)
        
    
class VestaFileHeader:
    '''
    classdocs
    '''


    def __init__(self,stream):
        '''
        Constructor
        '''
        params = struct.unpack('20s4H36s',stream[:64])
        self.stamp_Signature        = params[0]
        self.stamp_Version_Minor    = params[1]
        self.stamp_Version_Major    = params[2]
        self.stamp_Version_Build    = params[3]
        self.stamp_Version_Release  = params[4]
        self.stamp_Design           = params[5]
        
        params = struct.unpack('B2?Bd2I',stream[64:HEADER_SIZE])
        self.Radar          = dRadar[params[0]]
        self.DayLight       = params[1]
        self.Variance       = params[2]
        self.dummy          = params[3] # For saving proposes
        self.Obs_datetime   = OLE_TIME_ZERO + timedelta(
                                                days=float(params[4]))
        self.ppi_count      = params[5] 
        self.channel_count  = params[6]
        
        # For saving proposes
        self.windowsRadar = params[0]
        self.windowsTime = params[4]
        
    
    def getDesign(self):
        return self.stamp_Design.split(struct.pack('B',0))[0] 
        
    def toStream(self):
        return struct.pack('20s4H36sB2?Bd2I',self.stamp_Signature,
                           self.stamp_Version_Minor,
                           self.stamp_Version_Major,
                           self.stamp_Version_Build,
                           self.stamp_Version_Release,
                           self.stamp_Design,
                           self.windowsRadar,
                           self.DayLight,
                           self.Variance,
                           self.dummy,
                           self.windowsTime,
                           self.ppi_count,
                           self.channel_count)
        
        
class ChannelDesc:
    '''
    classdocs
    '''
    dWaveLength  = {0:'wl3cm', 1:'wl10cm', 2:'wl5cm'}
    dPulseLength = {0:'plLong', 1:'plShort'}

    def __init__(self,stream):
        '''
        Constructor
        '''
        params = struct.unpack('2Bh3I3fI',stream[:CHANNEL_SIZE])  
        self.wave_length        = self.dWaveLength[params[0]] 
        self.pulse              = self.dPulseLength[params[1]]
        self.dummy              = params[2] # For saving proposes
        self.number_of_cells    = params[3]
        self.cell_lenght        = params[4] # meters
        self.num_of_sectors     = params[5] # radials in 360 deg
        self.beam_width         = params[6] # deg
        self.met_potential      = params[7]
        self.delta_potential    = params[8]
        self.index              = params[9]
        
        # For saving proposes
        self.windowsWL      = params[0]
        self.windowsPulse   = params[1]
        
    def toStream(self):
        return struct.pack('2Bh3I3fI',self.windowsWL ,
                           self.windowsPulse,
                           self.dummy,
                           self.number_of_cells,
                           self.cell_lenght,
                           self.num_of_sectors,
                           self.beam_width,
                           self.met_potential,
                           self.delta_potential,
                           self.index)
        
            
    def print_channel(self):
        print   'wave_length :', self.wave_length,'\n',\
                'pulse :',self.pulse,'\n',\
                'number_of_cells :',self.number_of_cells,'\n',\
                'cell_lenght :',self.cell_lenght,'\n',\
                'num_of_sectors :',self.num_of_sectors,'\n',\
                'beam_width :',self.beam_width,'\n',\
                'met_potential :',self.met_potential,'\n',\
                'delta_potential :',self.delta_potential,'\n',\
                'index :',self.index
        

class Vesta_PPI_Header:
    '''
    classdocs
    '''
    dVestaPackMethod = {0:'pmNone', 1:'pmDAS', 2:'pmZLib'}

    def __init__(self,stream,loc):
        '''
        Constructor
        '''
        self.Description = PPI_Desc(stream,loc)
        params = struct.unpack('BH2I',stream[loc+PPI_DESC_SIZE:loc+
                                        PPI_DESC_SIZE+PPI_HEADER_SIZE])
        self.pack_Method    = self.dVestaPackMethod[params[0]]
        self.dummy          = params[1] # For saving proposes
        self.packed_Size    = params[2]
        self.unpacked_Size  = params[3]
        
        # For saving proposes
        self.windowPM = params[0]
        
    
    def toStream(self):
        data = struct.pack('BH2I',
                            self.windowPM,
                            self.dummy,
                            self.packed_Size,
                            self.unpacked_Size)
        return self.Description.toStream() + data
                            
        

class PPI_Desc:
    '''
    classdocs
    '''
    dPlaneKind = {0:'pkHorizontal', 1:'pkVertical'}
    def __init__(self,stream,loc):
        '''
        Constructor
        '''
        params = struct.unpack('3BdI2B3hI',
                               stream[loc:loc+PPI_DESC_SIZE])
        self.Radar          = dRadar[params[0]]
        self.speed          = params[1]
        self.dummy          = params[2] # For saving proposes
        self.time           = OLE_TIME_ZERO + timedelta(
                                                days=float(params[3]))
        self.channel        = params[4]
        self.kind           = self.dPlaneKind[params[5]]
        self.meassurement   = dMeasure[params[6]]
        self.angle          = code2angle_deg(params[7]) # deg
        self.start_az       = code2angle_deg(params[8]) # deg
        self.finish_az      = code2angle_deg(params[9]) # deg
        self.sectorCount    = params[10]
        
        # For saving proposes
        self.windowsRadar   = params[0]
        self.windowsTime    = params[3]
        self.windowskind    = params[5]
        self.windowsMeasure = params[6]
        
        
    def toStream(self):
        return struct.pack('3BdI2B3hI',self.windowsRadar,self.speed,
                    self.dummy,
                    self.windowsTime,self.channel,self.windowskind,
                    self.windowsMeasure,angle_deg2code(self.angle),
                    angle_deg2code(self.start_az),
                    angle_deg2code(self.finish_az),
                    self.sectorCount)                    
        
        
def code2angle_deg(code): 
    '''
    Converts from 16bits code to angle in deg
    '''      
    return code*360/4096.
        
        
def angle_deg2code(angle):  
    '''
    Converts from angle in deg to 16bits code
    '''      
    return int(angle/360*4096)
 
